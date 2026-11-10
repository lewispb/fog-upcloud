require "fog/core/collection"
require "fog/upcloud/compute/models/image"

module Fog
  module UpCloud
    class Compute
      class Images < Fog::Collection
        model Fog::UpCloud::Compute::Image

        # The account's private templates, or with type: :public UpCloud's
        # own, or with type: :all both. Filters: label and labels, as for
        # servers.
        def all(filters = {})
          filters = filters.dup
          type = filters.delete(:type) { :private }.to_s
          templates = service.list(:list_storages, "storages", "storage", "template", **Values.query(filters))
          load templates.select { |template| type == "all" || template["access"] == type }
        end

        def get(id)
          storage = service.get_storage(id).body.fetch("storage")
          new storage if storage["type"] == "template"
        rescue NotFound
          nil
        end
      end
    end
  end
end
