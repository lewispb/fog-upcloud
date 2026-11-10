# fog-upcloud

A [fog](https://github.com/fog/fog-core) provider for [UpCloud](https://upcloud.com)'s
API, 1.3: servers, plans, zones, storages, storage templates and server firewall rules.

## Install

```ruby
gem "fog-upcloud", github: "lewispb/fog-upcloud"
```

## Use

```ruby
require "fog/upcloud"

compute = Fog::Compute.new(provider: "UpCloud", upcloud_token: ENV["UPCLOUD_TOKEN"])

image = compute.images.all(labels: { "image" => "ci-linux" }).max_by(&:title)

server = compute.servers.create(
  zone: "de-fra1", plan: "2xCPU-4GB", template: image.id, hostname: "ci-1",
  storage_size: 80, labels: { "role" => "ci" }, firewall: true,
  ssh_keys: [ File.read("ci.pub") ], user_data: "#cloud-config\n"
)
server.wait_for { ready? }
server.public_ip_address

server.firewall_rules.create(
  direction: "in", action: "accept", family: "IPv4", protocol: "tcp",
  source_address_start: "198.51.100.0", source_address_end: "198.51.100.255",
  destination_port_start: 22, destination_port_end: 22, comment: "controller"
)

compute.servers.all(labels: { "role" => "ci" }).each(&:destroy)
```

UpCloud's nesting is flattened: labels are a Hash of key => value, `ip_addresses` and
`storage_devices` are Arrays, and `created` is a Time. Ids are UpCloud's UUIDs.

### Servers

```ruby
compute.servers.all                                      # every server, in brief
compute.servers.all(label: "role=ci")                    # or label: [ "role=ci", "pool" ]
compute.servers.all(labels: { "role" => "ci" }, state: "started")
compute.servers.get(id)                                  # nil when there's none

server.title, server.hostname, server.zone, server.plan, server.state, server.labels
server.created, server.ip_addresses, server.storage_devices, server.core_number, server.memory_amount
server.public_ip_address                                 # the first public IPv4 address
server.private_ip_address                                # the utility IPv4 address
server.ready?                                            # started
server.stopped?
server.start                                             # async: wait_for { ready? }
server.stop                                              # soft, hard after 60 s; or stop(type: "hard")
server.destroy                                           # stops hard, waits, deletes with storages and backups
server.destroy(timeout: 600)
server.reload
```

A server is created in a `zone` on a `plan`, with its disk cloned from `template`, the id
of a public or private template. `storage_size` (GB) and `storage_tier` (maxiops,
standard or hdd) size the disk; without them it's the template's size on the plan's
tier. `title` defaults to the hostname. `firewall` is `true` or `false`, or left out for
UpCloud's default, on. `interfaces` defaults to a public IPv4 and a utility IPv4:

```ruby
interfaces: [ { type: "public", family: "IPv4" }, { type: "public", family: "IPv6" }, { type: "utility" } ]
```

UpCloud's metadata service is always on, as cloud-init needs it. Cloud-init templates,
Ubuntu's among them, need `ssh_keys`, installed for `username` (root unless given).
`user_data` is a script, or a URL to one.

`destroy` stops a started server hard, waits up to `timeout` seconds (300) for UpCloud to
report it stopped, and deletes it with its storages and their backups. A server still
being created is in maintenance and is waited on until it can be stopped. A server
that's already gone counts as destroyed.

### Firewall rules

```ruby
server.firewall_rules.all                               # or compute.firewall_rules(server_id).all
server.firewall_rules.get(1)                            # by position, from 1
server.firewall_rules.create(direction: "in", action: "drop")
server.firewall_rules.create(direction: "in", action: "accept", family: "IPv4", protocol: "icmp", position: 1)
rule.destroy
```

A rule takes `direction` (in or out) and `action` (accept or drop), and optionally
`family` (needed with a protocol), `protocol` (tcp, udp or icmp), `icmp_type`,
`source_address_start`/`_end`, `source_port_start`/`_end`,
`destination_address_start`/`_end`, `destination_port_start`/`_end`, `comment` and
`position`. Ranges take both a start and an end. Rules are known by their position, so
removing one moves those after it up.

### Images

Images are storage templates.

```ruby
compute.images.all                                      # the account's private templates
compute.images.all(type: :public)                       # UpCloud's operating systems
compute.images.all(type: :all, label: "image=ci-linux")
compute.images.get(id)                                  # nil unless it's a template

image.title, image.zone, image.size, image.state, image.created, image.labels, image.template_type
image.ready?                                            # online
image.cloud_init?
image.destroy                                           # with its backups
```

### Storages

```ruby
compute.storages.all                                    # everything the account can see, public templates too
compute.storages.all(type: :normal, labels: { "role" => "ci" })
compute.storages.get(id)

storage.templatize(title: "ci-linux-20261110")          # an image, in maintenance until it's copied
storage.destroy                                         # with its backups
```

`type` is public, private, normal, backup, cdrom, template or favorite.

### Flavors and regions

```ruby
compute.flavors.all                                     # plans
compute.flavors.get("2xCPU-4GB")
flavor.name, flavor.core_number, flavor.memory_amount, flavor.storage_size, flavor.storage_tier

compute.regions.all                                     # zones
region.id, region.description, region.public?
```

### Requests

Each request is also on the service, returning UpCloud's JSON as the body:
`list_servers`, `get_server`, `list_ip_addresses`, `create_server`,
`start_server`, `stop_server`, `update_server`, `delete_server`,
`list_firewall_rules`, `create_firewall_rule`, `delete_firewall_rule`,
`replace_firewall_rules`, `list_storages`, `get_storage`, `delete_storage`,
`templatize_storage`, `list_plans` and `list_zones`.

```ruby
compute.list_servers(label: [ "role=ci" ]).body.dig("servers", "server")
```

### Settings

| Setting | Default | |
|---|---|---|
| `upcloud_token` | | An API token, `ucat_...`. |
| `upcloud_username`, `upcloud_password` | | Instead of a token: an account, best a subaccount, with API access. |
| `upcloud_url` | `https://api.upcloud.com` | |
| `persistent` | `false` | Keeps the connection open between requests. |
| `connection_options` | `{}` | Handed to Excon. |
| `retry_delays` | `[ 1, 2, 4 ]` | Seconds waited before each retry. |

A token or a username and password is required. A token is sent as Bearer
authentication, a username and password as Basic.

A request UpCloud rate limits (429) is retried whatever its method, since UpCloud turned
it away unprocessed. A 5xx or a dropped connection is retried for GET, PUT and DELETE
only, so a create is never sent twice. Other errors raise
`Fog::UpCloud::Compute::NotFound` (404) or `Fog::UpCloud::Compute::Error`, with UpCloud's
error code and message (`"409 SERVER_STATE_ILLEGAL The server is in a state in which it
cannot be used."`) and the code alone as `error.code`.

### Mocks

`Fog.mock!` swaps in an in-memory account per token or username, with a few of UpCloud's
zones, plans and public templates. Servers are started as soon as they're created and
stop at once; templates are online as soon as they're made. Servers, firewall rules,
storages and images behave as above, refusing what UpCloud refuses most often: deleting a
started server, or creating one from a template that doesn't exist.

## Develop

```sh
bundle install
bundle exec rake test
bundle exec rubocop
UPCLOUD_TOKEN=... bin/smoke                 # reads zones, plans and templates
UPCLOUD_TOKEN=... bin/smoke --boot de-fra1  # also boots, labels, firewalls and destroys the smallest Ubuntu server
```

## License

MIT
