require "fog/core/collection"
require "fog/upcloud/compute/models/flavor"

module Fog
  module UpCloud
    class Compute
      class Flavors < Fog::Collection
        model Fog::UpCloud::Compute::Flavor

        def all
          load service.list(:list_plans, "plans", "plan")
        end

        def get(name)
          all.find { |flavor| flavor.name == name }
        end
      end
    end
  end
end
