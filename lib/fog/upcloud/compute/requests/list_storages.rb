module Fog
  module UpCloud
    class Compute
      class Real
        # Every storage the account can see, or those of one type: public,
        # private, normal, backup, cdrom, template or favorite. Filter: label,
        # as for list_servers.
        def list_storages(type = nil, query = {})
          request method: :get, path: [ "storage", type ].compact.join("/"), query: query, expects: 200
        end
      end

      class Mock
        STORAGE_TYPES = { "public" => "access", "private" => "access", "normal" => "type", "backup" => "type", "cdrom" => "type", "template" => "type" }

        def list_storages(type = nil, query = {})
          listed = visible_storages.select do |storage|
            (type.nil? || storage[STORAGE_TYPES.fetch(type.to_s)] == type.to_s) && labelled?(storage["labels"], query[:label])
          end

          response 200, "storages" => { "storage" => listed }
        end
      end
    end
  end
end
