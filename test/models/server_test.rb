require "test_helper"

class ServerTest < UpCloudTest
  TEMPLATE = "01000000-0000-4000-8000-000030240200"

  def test_creates_a_server_from_a_template
    stub = stub_request(:post, "#{API}/server")
      .with(body: {
        "server" => {
          "zone" => "de-fra1", "plan" => "2xCPU-4GB", "hostname" => "ci-1", "title" => "ci-1", "metadata" => "yes", "firewall" => "on",
          "labels" => { "label" => [ { "key" => "role", "value" => "ci" } ] },
          "networking" => {
            "interfaces" => {
              "interface" => [
                { "type" => "public", "ip_addresses" => { "ip_address" => [ { "family" => "IPv4" } ] } },
                { "type" => "utility", "ip_addresses" => { "ip_address" => [ { "family" => "IPv4" } ] } }
              ]
            }
          },
          "storage_devices" => {
            "storage_device" => [ { "action" => "clone", "storage" => TEMPLATE, "title" => "ci-1", "size" => 80, "tier" => "maxiops" } ]
          },
          "login_user" => { "username" => "root", "create_password" => "no", "ssh_keys" => { "ssh_key" => [ "ssh-ed25519 AAAA ci" ] } },
          "user_data" => "#cloud-config\n"
        }
      })
      .to_return(status: 202, body: JSON.generate("server" => fixture(:server).merge("state" => "maintenance")))

    server = compute.servers.create(
      zone: "de-fra1", plan: "2xCPU-4GB", template: TEMPLATE, hostname: "ci-1", storage_size: 80, storage_tier: "maxiops",
      labels: { "role" => "ci" }, firewall: true, ssh_keys: [ "ssh-ed25519 AAAA ci" ], user_data: "#cloud-config\n"
    )

    assert_requested stub
    assert_equal "00c78863-db86-44ea-af70-d6edc4d162bf", server.id
    refute server.ready?
  end

  def test_creates_a_server_with_its_own_interfaces_and_title
    stub = stub_request(:post, "#{API}/server")
      .with { |request| JSON.parse(request.body)["server"].slice("title", "firewall", "networking", "labels", "login_user") == expected_minimal_body }
      .to_return(status: 202, body: JSON.generate("server" => fixture(:server)))

    compute.servers.create(
      zone: "de-fra1", plan: "2xCPU-4GB", template: TEMPLATE, hostname: "ci-1", title: "CI 1", firewall: false,
      interfaces: [ { type: "public", family: "IPv6" } ]
    )

    assert_requested stub
  end

  def test_requires_a_zone_plan_hostname_and_template
    assert_raises(ArgumentError) { compute.servers.create(zone: "de-fra1", plan: "2xCPU-4GB", hostname: "ci-1") }
  end

  def test_will_not_save_a_server_twice
    assert_raises(Fog::Errors::Error) { compute.servers.new(fixture(:server)).save }
  end

  def test_flattens_upclouds_server
    server = compute.servers.new(fixture(:server))

    assert server.ready?
    assert_equal "ci-1", server.title
    assert_equal "de-fra1", server.zone
    assert_equal({ "role" => "ci" }, server.labels)
    assert_equal Time.utc(2026, 11, 7, 19, 30), server.created
    assert_equal "203.0.113.10", server.public_ip_address
    assert_equal "10.6.3.95", server.private_ip_address
    assert_equal 3, server.ip_addresses.size
    assert_equal "01f3286c-a5ea-4670-8121-d0b9767d625b", server.storage_devices.first["storage"]
    assert_equal 2, server.core_number
    assert server.firewall
  end

  def test_lists_servers_by_label
    stub = stub_upcloud(:get, "server?label=role%3Dci&label=pool%3Dlinux", body: list("servers", "server", [ fixture(:listed_server) ]))

    server = only(compute.servers.all(label: "role=ci", labels: { "pool" => "linux" }))

    assert_requested stub
    assert_equal({ "role" => "ci" }, server.labels)
    assert_nil server.public_ip_address
  end

  def test_lists_every_server
    stub_upcloud :get, "server", body: list("servers", "server", [ fixture(:listed_server) ])

    assert_equal [ "ci-1" ], compute.servers.all.map(&:hostname)
  end

  def test_get_returns_nil_for_a_missing_server
    stub_upcloud :get, "server/missing", status: 404, body: error("SERVER_NOT_FOUND", "The server missing does not exist.")

    assert_nil compute.servers.get("missing")
  end

  def test_waits_for_a_server_to_start
    stub_request(:get, "#{API}/server/#{fixture(:server)["uuid"]}")
      .to_return({ body: JSON.generate("server" => fixture(:server).merge("state" => "maintenance")) }, { body: JSON.generate("server" => fixture(:server)) })
    server = compute.servers.new(fixture(:server).merge("state" => "maintenance"))

    server.wait_for(5, 0) { ready? }

    assert server.ready?
  end

  def test_starts_and_stops_a_server
    server = compute.servers.new(fixture(:server))
    start = stub_request(:post, "#{API}/server/#{server.id}/start")
      .with(body: { "server" => { "start_type" => "async" } })
      .to_return(body: JSON.generate("server" => fixture(:server)))
    stop = stub_request(:post, "#{API}/server/#{server.id}/stop")
      .with(body: { "stop_server" => { "stop_type" => "soft", "timeout" => "60" } })
      .to_return(body: JSON.generate("server" => fixture(:server)))

    server.start
    server.stop

    assert_requested start
    assert_requested stop
  end

  def test_destroys_a_started_server_once_its_stopped
    id = fixture(:server)["uuid"]
    stub_request(:get, "#{API}/server/#{id}").to_return(
      { body: JSON.generate("server" => fixture(:server)) },
      { body: JSON.generate("server" => fixture(:server)) },
      { body: JSON.generate("server" => fixture(:server).merge("state" => "stopped")) }
    )
    stop = stub_request(:post, "#{API}/server/#{id}/stop")
      .with(body: { "stop_server" => { "stop_type" => "hard", "timeout" => "60" } })
      .to_return(body: JSON.generate("server" => fixture(:server)))
    delete = stub_upcloud(:delete, "server/#{id}?storages=1&backups=delete", status: 204)

    assert compute.servers.new(fixture(:server)).destroy(interval: 0)
    assert_requested stop, times: 2
    assert_requested delete
  end

  def test_destroys_a_server_still_being_created_once_it_can_be_stopped
    id = fixture(:server)["uuid"]
    stub_request(:get, "#{API}/server/#{id}").to_return(
      { body: JSON.generate("server" => fixture(:server).merge("state" => "maintenance")) },
      { body: JSON.generate("server" => fixture(:server).merge("state" => "stopped")) }
    )
    delete = stub_upcloud(:delete, "server/#{id}?storages=1&backups=delete", status: 204)

    assert compute.servers.new(fixture(:server)).destroy(interval: 0)
    assert_requested delete
  end

  def test_destroying_carries_on_when_the_server_stopped_by_itself
    id = fixture(:server)["uuid"]
    stub_request(:get, "#{API}/server/#{id}").to_return(
      { body: JSON.generate("server" => fixture(:server)) },
      { body: JSON.generate("server" => fixture(:server).merge("state" => "stopped")) }
    )
    stub_upcloud :post, "server/#{id}/stop", status: 409, body: error("SERVER_STATE_ILLEGAL", "The server is in a state in which it cannot be used.")
    delete = stub_upcloud(:delete, "server/#{id}?storages=1&backups=delete", status: 204)

    assert compute.servers.new(fixture(:server)).destroy(interval: 0)
    assert_requested delete
  end

  def test_destroying_a_server_thats_gone_succeeds
    id = fixture(:server)["uuid"]
    stub_upcloud :get, "server/#{id}", status: 404, body: error("SERVER_NOT_FOUND", "The server #{id} does not exist.")

    assert compute.servers.new(fixture(:server)).destroy
  end

  def test_gives_up_destroying_a_server_that_wont_stop
    id = fixture(:server)["uuid"]
    stub_upcloud :get, "server/#{id}", body: { "server" => fixture(:server).merge("state" => "maintenance") }

    assert_raises(Fog::Errors::TimeoutError) { compute.servers.new(fixture(:server)).destroy(timeout: 0, interval: 0) }
  end

  private
    def expected_minimal_body
      {
        "title" => "CI 1", "firewall" => "off", "labels" => { "label" => [] },
        "networking" => { "interfaces" => { "interface" => [ { "type" => "public", "ip_addresses" => { "ip_address" => [ { "family" => "IPv6" } ] } } ] } }
      }
    end
end
