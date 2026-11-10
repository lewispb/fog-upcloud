require "fog/upcloud"

module Fog
  module UpCloud
    # UpCloud's API, 1.3 (https://developers.upcloud.com/1.3/).
    #
    #   compute = Fog::Compute.new(provider: "UpCloud", upcloud_token: ENV["UPCLOUD_TOKEN"])
    #   compute.servers.all(labels: { "role" => "ci" })
    #
    # Settings: upcloud_token, an API token (ucat_...), or upcloud_username
    # and upcloud_password, an account or subaccount with API access; one of
    # the two is required. upcloud_url, the API's base URL; persistent, to keep
    # the connection open between requests; connection_options, handed to
    # Excon; retry_delays, the seconds waited before each retry of a request
    # UpCloud rate limits or fails with a 5xx (default 1, 2 and 4).
    class Compute < Fog::Service
      recognizes :upcloud_token, :upcloud_username, :upcloud_password
      recognizes :upcloud_url, :persistent, :connection_options, :retry_delays

      model_path "fog/upcloud/compute/models"
      model :server
      collection :servers
      model :flavor
      collection :flavors
      model :region
      collection :regions
      model :storage
      collection :storages
      model :image
      collection :images
      model :firewall_rule

      request_path "fog/upcloud/compute/requests"
      request :list_servers
      request :get_server
      request :create_server
      request :start_server
      request :stop_server
      request :delete_server
      request :update_server
      request :list_ip_addresses
      request :list_firewall_rules
      request :create_firewall_rule
      request :delete_firewall_rule
      request :replace_firewall_rules
      request :list_storages
      request :get_storage
      request :delete_storage
      request :templatize_storage
      request :list_plans
      request :list_zones

      # UpCloud's error_code, such as SERVER_STATE_ILLEGAL, on the errors a
      # request raises
      module ErrorCode
        attr_reader :code

        def initialize(message = nil, code = nil)
          super(message)
          @code = code
        end
      end

      class Error
        include ErrorCode
      end

      class NotFound
        include ErrorCode
      end

      # A server's firewall rules, as a collection that isn't declared with
      # fog's collection, which would take only a Hash
      module Collections
        def firewall_rules(server_id)
          require "fog/upcloud/compute/models/firewall_rules"
          FirewallRules.new(service: self, server_id: server_id.is_a?(Hash) ? server_id.fetch(:server_id) : server_id)
        end
      end

      def self.validate_options(options)
        super

        unless options[:upcloud_token] || (options[:upcloud_username] && options[:upcloud_password])
          raise ArgumentError, "Missing required arguments: upcloud_token, or upcloud_username and upcloud_password"
        end
      end
    end
  end
end

require "fog/upcloud/compute/values"
require "fog/upcloud/compute/lists"
require "fog/upcloud/compute/real"
require "fog/upcloud/compute/mock"
