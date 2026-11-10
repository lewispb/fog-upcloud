module Fog
  module UpCloud
    class Compute
      class Real
        # Removes the rule at position (from 1) in a server's firewall. The
        # rules after it move up one.
        def delete_firewall_rule(server_id, position)
          request method: :delete, path: "server/#{server_id}/firewall_rule/#{position}", expects: 204
        end
      end

      class Mock
        def delete_firewall_rule(server_id, position)
          find_server server_id
          rules = data[:firewall_rules][server_id]
          index = Integer(position) - 1
          refuse NotFound, 404, "FIREWALL_RULE_NOT_FOUND", "The firewall rule does not exist." unless index.between?(0, rules.size - 1)

          rules.delete_at(index)
          response 204
        end
      end
    end
  end
end
