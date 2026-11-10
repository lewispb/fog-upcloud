module Fog
  module UpCloud
    class Compute
      class Real
        # Creates a server from the attributes of UpCloud's server block:
        # zone, title, hostname, plan, storage_devices and networking, and
        # optionally labels, firewall ("on" or "off"), metadata, login_user,
        # user_data and the rest of UpCloud's create options.
        def create_server(attributes)
          request method: :post, path: "server", body: { server: attributes }, expects: 202
        end
      end

      class Mock
        def create_server(attributes)
          attributes = wire(attributes)
          missing = [ "zone", "title", "hostname", "storage_devices" ].reject { |key| attributes.key?(key) }
          refuse Error, 400, "#{missing.first.upcase}_MISSING", "The required attribute #{missing.first} is missing from the request." if missing.any?
          refuse NotFound, 404, "ZONE_NOT_FOUND", "The zone #{attributes["zone"]} does not exist." unless ZONES.any? { |zone| zone["id"] == attributes["zone"] }

          server = mocked_server(attributes)
          data[:servers][server["uuid"]] = server
          response 202, "server" => server
        end

        private
          def mocked_server(attributes)
            plan = PLANS.find { |candidate| candidate["name"] == attributes["plan"] } || PLANS.first

            {
              "uuid" => identifier("00"), "state" => "started", "created" => now.to_i, "firewall" => "on",
              "core_number" => plan["core_number"].to_s, "memory_amount" => plan["memory_amount"].to_s,
              "labels" => { "label" => [] }, "tags" => { "tag" => [] },
              "ip_addresses" => { "ip_address" => mocked_ip_addresses(attributes) },
              "storage_devices" => { "storage_device" => mocked_disks(attributes) }
            }.merge(attributes.slice("zone", "title", "hostname", "plan", "labels", "firewall", "metadata"))
          end

          def mocked_ip_addresses(attributes)
            interfaces = attributes.dig("networking", "interfaces", "interface") || []

            interfaces.flat_map do |interface|
              interface.dig("ip_addresses", "ip_address").to_a.map do |address|
                { "access" => interface["type"], "family" => address.fetch("family", "IPv4"), "address" => mocked_address(interface["type"]) }
              end
            end
          end

          def mocked_address(access)
            access == "public" ? "192.0.2.#{rand(1..254)}" : "10.1.0.#{rand(1..254)}"
          end

          # Clones each template into a disk of the account's
          def mocked_disks(attributes)
            attributes.dig("storage_devices", "storage_device").to_a.map do |device|
              template = find_storage(device["storage"])
              disk = {
                "uuid" => identifier("01"), "access" => "private", "type" => "normal", "state" => "online", "zone" => attributes["zone"],
                "title" => device.fetch("title", template["title"]), "size" => device.fetch("size", template["size"]),
                "tier" => device.fetch("tier", "maxiops"), "labels" => device.fetch("labels", []), "license" => 0, "created" => now.iso8601
              }
              data[:storages][disk["uuid"]] = disk

              { "storage" => disk["uuid"], "storage_title" => disk["title"], "storage_size" => disk["size"], "storage_tier" => disk["tier"], "type" => "disk" }
            end
          end
      end
    end
  end
end
