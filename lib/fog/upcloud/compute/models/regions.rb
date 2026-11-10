require "fog/core/collection"
require "fog/upcloud/compute/models/region"

module Fog
  module UpCloud
    class Compute
      class Regions < Fog::Collection
        model Fog::UpCloud::Compute::Region

        def all
          load service.list(:list_zones, "zones", "zone")
        end

        def get(id)
          all.find { |region| region.id == id }
        end
      end
    end
  end
end
