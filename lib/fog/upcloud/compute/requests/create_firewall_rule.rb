module Fog
  module UpCloud
    class Compute
      class Real
        # Adds a rule to a server's firewall from the attributes of UpCloud's
        # firewall_rule block: direction (in or out) and action (accept or
        # drop), and optionally family (IPv4 or IPv6, needed with a protocol),
        # protocol (tcp, udp or icmp), the source and destination address and
        # port ranges, icmp_type, comment, and position, which is last when
        # it's not given.
        def create_firewall_rule(server_id, attributes)
          request method: :post, path: "server/#{server_id}/firewall_rule", body: { firewall_rule: attributes }, expects: 201
        end
      end

      class Mock
        def create_firewall_rule(server_id, attributes)
          find_server server_id
          attributes = wire(attributes)
          [ "direction", "action" ].each do |key|
            refuse Error, 400, "#{key.upcase}_MISSING", "The required attribute #{key} is missing from the request." unless attributes.key?(key)
          end

          rules = data[:firewall_rules][server_id]
          position = attributes.delete("position")
          index = position ? Integer(position).clamp(1, rules.size + 1) - 1 : rules.size
          rules.insert(index, attributes)
          response 201, "firewall_rule" => positioned(server_id).fetch(index)
        end
      end
    end
  end
end
