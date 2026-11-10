module Fog
  module UpCloud
    class Compute
      class Real
        # Replaces the whole of a server's firewall with rules, each the
        # attributes of a firewall_rule block, in order. A server in
        # maintenance, still being created or changed, can't take them.
        def replace_firewall_rules(server_id, rules)
          request method: :put, path: "server/#{server_id}/firewall_rule", body: { firewall_rules: { firewall_rule: rules } }, expects: 204
        end
      end

      class Mock
        def replace_firewall_rules(server_id, rules)
          server = find_server(server_id)
          refuse Error, 409, "SERVER_STATE_ILLEGAL", "The server is in a state in which it cannot be used." if server["state"] == "maintenance"

          data[:firewall_rules][server_id] = rules.map { |rule| wire(rule).except("position") }
          response 204
        end
      end
    end
  end
end
