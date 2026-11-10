module Fog
  module UpCloud
    class Compute
      # Fog.mock! stands this in for Real: an account kept in memory per token
      # or username, with a few of UpCloud's zones, plans and public templates.
      # Servers are started as soon as they're created and stop at once;
      # templatized storages are online at once.
      class Mock
        include Lists

        ZONES = [
          { "id" => "de-fra1", "description" => "Frankfurt #1", "public" => "yes" },
          { "id" => "fi-hel1", "description" => "Helsinki #1", "public" => "yes" },
          { "id" => "us-chi1", "description" => "Chicago #1", "public" => "yes" },
          { "id" => "us-nyc1", "description" => "New York #1", "public" => "yes" },
          { "id" => "us-sjo1", "description" => "San Jose #1", "public" => "yes" }
        ]
        PLANS = [
          { "name" => "1xCPU-1GB", "core_number" => 1, "memory_amount" => 1024, "storage_size" => 25, "storage_tier" => "maxiops",
            "public_traffic_out" => 1024 },
          { "name" => "2xCPU-4GB", "core_number" => 2, "memory_amount" => 4096, "storage_size" => 80, "storage_tier" => "maxiops",
            "public_traffic_out" => 4096 },
          { "name" => "16xCPU-64GB", "core_number" => 16, "memory_amount" => 65536, "storage_size" => 960, "storage_tier" => "maxiops",
            "public_traffic_out" => 24576 }
        ]
        TEMPLATES = [
          { "uuid" => "01000000-0000-4000-8000-000030240200", "title" => "Ubuntu Server 24.04 LTS (Noble Numbat)", "access" => "public",
            "type" => "template", "template_type" => "cloud-init", "size" => 4, "state" => "online", "license" => 0, "labels" => [] },
          { "uuid" => "01000000-0000-4000-8000-000010080300", "title" => "Windows Server 2022 Standard", "access" => "public",
            "type" => "template", "template_type" => "native", "size" => 30, "state" => "online", "license" => 0, "labels" => [] }
        ]

        def self.data
          @data ||= Hash.new do |data, account|
            data[account] = { servers: {}, storages: {}, firewall_rules: Hash.new { |rules, id| rules[id] = [] } }
          end
        end

        def self.reset
          @data = nil
        end

        def initialize(options = {})
          @account = options[:upcloud_token] || options[:upcloud_username].to_s
        end

        def data
          self.class.data[@account]
        end

        def reset_data
          self.class.data.delete(@account)
        end

        private
          def response(status, body = nil)
            Excon::Response.new(status: status, body: body)
          end

          # The attributes as UpCloud would read them off the wire: string
          # keys, all the way down
          def wire(attributes)
            Fog::JSON.decode(Fog::JSON.encode(attributes))
          end

          def find_server(id)
            data[:servers].fetch(id) { refuse NotFound, 404, "SERVER_NOT_FOUND", "The server #{id} does not exist." }
          end

          def find_storage(id)
            visible_storages.find { |storage| storage["uuid"] == id } || refuse(NotFound, 404, "STORAGE_NOT_FOUND", "The storage #{id} does not exist.")
          end

          def visible_storages
            TEMPLATES + data[:storages].values
          end

          def refuse(error, status, code, message)
            raise error.new("#{status} #{code} #{message}", code)
          end

          # Whether a resource's labels match every label=key or
          # label=key=value filter, keys ignoring case
          def labelled?(labels, filters)
            Array(filters).all? do |filter|
              key, value = filter.split("=", 2)
              labels.any? { |label| label["key"].casecmp?(key) && (value.nil? || label["value"] == value) }
            end
          end

          def now
            Time.now.utc
          end

          def identifier(prefix)
            "#{prefix}#{Fog::UUID.uuid[2..]}"
          end
      end
    end
  end
end
