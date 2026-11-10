module Fog
  module UpCloud
    class Compute
      class Real
        # Deletes a storage that's online and not attached to a server.
        # backups ("keep", "keep_latest" or "delete") says what becomes of its
        # backups.
        def delete_storage(id, query = {})
          request method: :delete, path: "storage/#{id}", query: query, expects: 204
        end
      end

      class Mock
        def delete_storage(id, query = {})
          storage = find_storage(id)
          refuse Error, 403, "STORAGE_FORBIDDEN", "The storage exists, but is owned by another account." unless storage["access"] == "private"
          refuse Error, 409, "STORAGE_ATTACHED", "The storage is currently attached to a server." if attached?(id)

          data[:storages].delete(id)
          response 204
        end

        private
          def attached?(id)
            data[:servers].values.any? { |server| server.dig("storage_devices", "storage_device").any? { |device| device["storage"] == id } }
          end
      end
    end
  end
end
