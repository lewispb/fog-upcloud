require "fog/core/model"
require "fog/upcloud/compute/models/storage_attributes"

module Fog
  module UpCloud
    class Compute
      # A storage template, to create servers from by its id: public, one of
      # UpCloud's operating systems, or private, from templatize. Its
      # template_type is cloud-init (needing SSH keys) or native.
      class Image < Fog::Model
        include StorageAttributes

        def cloud_init?
          template_type == "cloud-init"
        end
      end
    end
  end
end
