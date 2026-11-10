require "fog/core/model"

module Fog
  module UpCloud
    class Compute
      # A plan, by its name. memory_amount is in MB, storage_size in GB and
      # public_traffic_out in GB a month.
      class Flavor < Fog::Model
        identity :id, aliases: "name"

        attribute :core_number, type: :integer
        attribute :memory_amount, type: :integer
        attribute :storage_size, type: :integer
        attribute :storage_tier
        attribute :public_traffic_out, type: :integer
        attribute :gpu_amount, type: :integer
        attribute :gpu_model

        def name
          id
        end
      end
    end
  end
end
