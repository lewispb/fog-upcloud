require "fog/core/model"
require "fog/upcloud/compute/models/storage_attributes"

module Fog
  module UpCloud
    class Compute
      # A storage: a disk (type normal), a backup, a CD-ROM or a template
      class Storage < Fog::Model
        include StorageAttributes

        # Copies the storage into a private template, returned as an image
        # that's in maintenance until the copy's done. A disk is copied from a
        # stopped server.
        def templatize(title:)
          requires :id
          service.images.new(service.templatize_storage(id, title: title).body.fetch("storage"))
        end
      end
    end
  end
end
