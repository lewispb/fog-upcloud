module Fog
  module UpCloud
    class Compute
      class Real
        # Every server, in brief. Filters: label ("env=ci", or a key alone;
        # an Array for several, all of which must match), state, tag, uuid
        # and search.
        def list_servers(query = {})
          request method: :get, path: "server", query: query, expects: 200
        end
      end

      class Mock
        def list_servers(query = {})
          servers = data[:servers].values.select do |server|
            labelled?(server.dig("labels", "label"), query[:label]) && (query[:state].nil? || server["state"] == query[:state])
          end

          response 200, "servers" => { "server" => servers.map { |server| server.except("ip_addresses", "networking", "storage_devices") } }
        end
      end
    end
  end
end
