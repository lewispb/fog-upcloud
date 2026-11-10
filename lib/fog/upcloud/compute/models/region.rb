require "fog/core/model"

module Fog
  module UpCloud
    class Compute
      # A zone. A private cloud's zone isn't public and has a parent_zone.
      class Region < Fog::Model
        identity :id

        attribute :description
        attribute :public
        attribute :parent_zone

        def public?
          public == "yes"
        end
      end
    end
  end
end
