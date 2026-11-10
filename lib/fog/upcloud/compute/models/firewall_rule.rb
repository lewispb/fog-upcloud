require "fog/core/model"

module Fog
  module UpCloud
    class Compute
      # A rule in a server's firewall, known by its position, from 1, in the
      # order the rules are checked. Address and port ranges take both a
      # start and an end, the same for one address or port; ports go with
      # tcp or udp.
      #
      #   server.firewall_rules.create(
      #     direction: "in", action: "accept", family: "IPv4", protocol: "tcp",
      #     source_address_start: "198.51.100.0", source_address_end: "198.51.100.255",
      #     destination_port_start: 22, destination_port_end: 22, comment: "controller"
      #   )
      class FirewallRule < Fog::Model
        CREATED = [
          :direction, :action, :family, :protocol, :icmp_type, :source_address_start, :source_address_end, :source_port_start,
          :source_port_end, :destination_address_start, :destination_address_end, :destination_port_start, :destination_port_end,
          :comment, :position
        ]

        identity :position, type: :integer

        attribute :server_id
        attribute :direction
        attribute :action
        attribute :family
        attribute :protocol
        attribute :icmp_type
        attribute :source_address_start
        attribute :source_address_end
        attribute :source_port_start
        attribute :source_port_end
        attribute :destination_address_start
        attribute :destination_address_end
        attribute :destination_port_start
        attribute :destination_port_end
        attribute :comment

        # Adds the rule, last unless position says where. A rule with a
        # position is persisted by fog's measure, so saving one twice isn't
        # refused here; UpCloud refuses an identical rule (FIREWALL_RULE_EXISTS).
        def save
          requires :server_id, :direction, :action
          merge_attributes service.create_firewall_rule(server_id, creation_attributes).body.fetch("firewall_rule")
          true
        end

        # Removes the rule. The rules after it move up one, so a collection
        # loaded before has their old positions.
        def destroy
          requires :server_id, :position
          service.delete_firewall_rule(server_id, position)
          true
        end

        private
          # UpCloud's examples give numbers as strings
          def creation_attributes
            attributes.slice(*CREATED).compact.transform_values { |value| value.is_a?(Integer) ? value.to_s : value }
          end
      end
    end
  end
end
