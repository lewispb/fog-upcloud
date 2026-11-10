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

        def new(attributes = {})
          super({ server_id: server_id }.merge(attributes))
        end
      end
    end
  end
end
