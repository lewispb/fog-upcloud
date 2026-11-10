require "fog/core/collection"
require "fog/upcloud/compute/models/firewall_rule"

module Fog
  module UpCloud
    class Compute
      # The rules of one server's firewall: server.firewall_rules, or
      # compute.firewall_rules(server_id)
      class FirewallRules < Fog::Collection
        model Fog::UpCloud::Compute::FirewallRule

        attribute :server_id

        def all
          requires :server_id
          load service.list(:list_firewall_rules, "firewall_rules", "firewall_rule", server_id)
        end

        def get(position)
          all.find { |rule| rule.position == Integer(position) }
        end

        # Replaces the whole firewall with rules, each a rule's attributes,
        # in order, in one request
        def replace(rules)
          requires :server_id
          service.replace_firewall_rules(server_id, rules.map { |rule| Values.rule_block(rule) })
          all
        end

        def new(attributes = {})
          super({ server_id: server_id }.merge(attributes))
        end
      end
    end
  end
end
