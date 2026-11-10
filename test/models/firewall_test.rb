require "test_helper"

class FirewallTest < UpCloudTest
  def test_adds_a_rule_to_a_server
    server = compute.servers.new(fixture(:server))
    stub = stub_request(:post, "#{API}/server/#{server.id}/firewall_rule")
      .with(body: {
        "firewall_rule" => {
          "direction" => "in", "action" => "accept", "family" => "IPv4", "protocol" => "tcp",
          "source_address_start" => "198.51.100.0", "source_address_end" => "198.51.100.255",
          "destination_port_start" => "22", "destination_port_end" => "22", "comment" => "controller"
        }
      })
      .to_return(status: 201, body: JSON.generate("firewall_rule" => fixture(:firewall_rule)))

    rule = server.firewall_rules.create(
      direction: "in", action: "accept", family: "IPv4", protocol: "tcp",
      source_address_start: "198.51.100.0", source_address_end: "198.51.100.255",
      destination_port_start: 22, destination_port_end: 22, comment: "controller"
    )

    assert_requested stub
    assert_equal 1, rule.position
  end

  def test_adds_a_rule_at_a_position
    stub = stub_request(:post, "#{API}/server/abc/firewall_rule")
      .with(body: { "firewall_rule" => { "direction" => "in", "action" => "drop", "position" => "1" } })
      .to_return(status: 201, body: JSON.generate("firewall_rule" => fixture(:firewall_rule).merge("action" => "drop")))

    compute.firewall_rules("abc").create(direction: "in", action: "drop", position: 1)

    assert_requested stub
  end

  def test_lists_and_removes_a_servers_rules
    stub_upcloud :get, "server/abc/firewall_rule", body: list("firewall_rules", "firewall_rule", [ fixture(:firewall_rule) ])
    stub = stub_upcloud(:delete, "server/abc/firewall_rule/1", status: 204)

    rule = compute.firewall_rules("abc").get(1)
    assert_equal "198.51.100.0", rule.source_address_start

    assert rule.destroy
    assert_requested stub
  end

  def test_requires_a_direction_and_action
    assert_raises(ArgumentError) { compute.firewall_rules("abc").create(protocol: "tcp") }
  end
end
