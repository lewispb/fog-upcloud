require "fog/core/collection"
require "fog/upcloud/compute/models/server"

module Fog
  module UpCloud
    class Compute
      class Servers < Fog::Collection
        model Fog::UpCloud::Compute::Server

        # Every server, in brief: without its addresses or storage devices,
        # which get or reload gives. Filters: label: "role=ci" (or a key
        # alone, or an Array of either) and labels: { "role" => "ci" }, all of
        # which must match; and state, tag, uuid and search, as for
        # list_servers.
        def all(filters = {})
          load service.list(:list_servers, "servers", "server", **Values.query(filters))
        end

        def get(id)
          new service.get_server(id).body.fetch("server")
        rescue NotFound
          nil
        end
      end
    end
  end
end
