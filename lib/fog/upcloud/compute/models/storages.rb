require "fog/core/collection"
require "fog/upcloud/compute/models/storage"

module Fog
  module UpCloud
    class Compute
      class Storages < Fog::Collection
        model Fog::UpCloud::Compute::Storage

        # Every storage the account can see, public templates and CD-ROMs
        # included, or those of one type: public, private, normal, backup,
        # cdrom, template or favorite. Filters: label and labels, as for
        # servers.
        def all(filters = {})
          filters = filters.dup
          load service.list(:list_storages, "storages", "storage", filters.delete(:type)&.to_s, **Values.query(filters))
        end

        def get(id)
          new service.get_storage(id).body.fetch("storage")
        rescue NotFound
          nil
        end
      end
    end
  end
end
