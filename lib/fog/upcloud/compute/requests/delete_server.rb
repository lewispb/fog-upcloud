module Fog
  module UpCloud
    class Compute
      class Real
        # Deletes a stopped server. With storages: 1 its storages go too, and
        # backups ("keep", "keep_latest" or "delete") says what becomes of
        # their backups.
        def delete_server(id, query = {})
          request method: :delete, path: "server/#{id}", query: query, expects: 204
        end
      end

      class Mock
        def delete_server(id, query = {})
          server = find_server(id)
          refuse Error, 409, "SERVER_STATE_ILLEGAL", "The server is in a state in which it cannot be used." unless server["state"] == "stopped"

          if [ 1, "1", true, "true" ].include?(query[:storages])
            server.dig("storage_devices", "storage_device").each { |device| data[:storages].delete(device["storage"]) }
          end
          data[:servers].delete(id)
          data[:firewall_rules].delete(id)
          response 204
        end
      end
    end
  end
end
