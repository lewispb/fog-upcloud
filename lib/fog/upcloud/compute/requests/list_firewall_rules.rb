module Fog
  module UpCloud
    class Compute
      class Real
        # A server's firewall rules, in the order they're checked
        def list_firewall_rules(server_id)
          request method: :get, path: "server/#{server_id}/firewall_rule", expects: 200
        end
      end

      class Mock
        def list_firewall_rules(server_id)
          find_server server_id
          response 200, "firewall_rules" => { "firewall_rule" => positioned(server_id) }
        end

        private
          def positioned(server_id)
            data[:firewall_rules][server_id].each_with_index.map { |rule, index| rule.merge("position" => (index + 1).to_s) }
          end
      end
    end
  end
end
