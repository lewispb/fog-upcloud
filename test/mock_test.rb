require "test_helper"

class MockTest < UpCloudTest
  UBUNTU = "01000000-0000-4000-8000-000030240200"

  def setup
    Fog.mock!
    Fog::UpCloud::Compute::Mock.reset
  end

  def teardown
    Fog.unmock!
  end

  def test_runs_a_server_from_a_template_and_removes_it
    server = compute.servers.create(zone: "de-fra1", plan: "2xCPU-4GB", template: UBUNTU, hostname: "ci-1", labels: { "role" => "ci" })

    assert server.ready?
    assert server.public_ip_address
    assert_equal [ server.id ], compute.servers.all(labels: { "role" => "ci" }).map(&:id)
    assert_empty compute.servers.all(label: "role=windows")

    disk = server.storage_devices.first["storage"]
    assert_equal UBUNTU, compute.storages.get(disk).origin
    server.destroy
    assert_nil compute.servers.get(server.id)
    assert_nil compute.storages.get(disk)
  end

  def test_templatizes_a_servers_disk
    server = compute.servers.create(zone: "de-fra1", plan: "2xCPU-4GB", template: UBUNTU, hostname: "golden")
    server.stop
    image = compute.storages.get(server.storage_devices.first["storage"]).templatize(title: "ci-linux")

    assert_equal [ image.id ], compute.images.all.map(&:id)
    assert_includes compute.images.all(type: :public).map(&:title), "Ubuntu Server 24.04 LTS (Noble Numbat)"

    image.destroy
    assert_empty compute.images.all
  end

  def test_keeps_a_servers_firewall_rules_in_order
    server = compute.servers.create(zone: "de-fra1", plan: "2xCPU-4GB", template: UBUNTU, hostname: "ci-1")
    server.firewall_rules.create(direction: "in", action: "accept", family: "IPv4", protocol: "tcp", destination_port_start: 22, destination_port_end: 22)
    server.firewall_rules.create(direction: "in", action: "drop")
    server.firewall_rules.create(direction: "in", action: "accept", family: "IPv4", protocol: "icmp", position: 1)

    assert_equal [ [ 1, "icmp" ], [ 2, "tcp" ], [ 3, nil ] ], server.firewall_rules.all.map { |rule| [ rule.position, rule.protocol ] }

    server.firewall_rules.get(1).destroy
    assert_equal [ "tcp", nil ], compute.firewall_rules(server.id).all.map(&:protocol)
  end

  def test_replaces_a_servers_firewall_and_labels
    server = compute.servers.create(zone: "us-sjo1", plan: "2xCPU-4GB", template: UBUNTU, hostname: "ci-1", labels: { "role" => "ci" })
    server.firewall_rules.replace([ { direction: "in", action: "accept", family: "IPv4", protocol: "icmp" }, { direction: "in", action: "drop" } ])
    server.update_labels("role" => "ci", "firewall" => "set")

    assert_equal [ "icmp", nil ], server.firewall_rules.all.map(&:protocol)
    assert_equal [ server.id ], compute.servers.all(labels: { "firewall" => "set" }).map(&:id)
  end

  def test_refuses_to_delete_a_started_server
    server = compute.servers.create(zone: "de-fra1", plan: "2xCPU-4GB", template: UBUNTU, hostname: "ci-1")

    error = assert_raises(Fog::UpCloud::Compute::Error) { compute.delete_server(server.id) }
    assert_equal "SERVER_STATE_ILLEGAL", error.code
  end

  def test_refuses_a_server_from_a_missing_template
    assert_raises(Fog::UpCloud::Compute::NotFound) do
      compute.servers.create(zone: "de-fra1", plan: "2xCPU-4GB", template: "01000000-missing", hostname: "ci-1")
    end
  end

  def test_lists_the_catalog
    assert_equal "1xCPU-1GB", compute.flavors.all.min_by(&:memory_amount).name
    assert_includes compute.regions.all.map(&:id), "de-fra1"
  end

  def test_keeps_each_accounts_data_apart
    compute.servers.create(zone: "de-fra1", plan: "2xCPU-4GB", template: UBUNTU, hostname: "ci-1")
    other = Fog::Compute.new(provider: "UpCloud", upcloud_username: "other", upcloud_password: "secret")

    assert_empty other.servers.all
  end
end
