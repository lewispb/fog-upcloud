module Fog
  module UpCloud
    class Compute
      class Real
        # Copies a storage into a private template, to create servers from.
        # The template is in maintenance until the copy's done, then online.
        def templatize_storage(id, attributes)
          request method: :post, path: "storage/#{id}/templatize", body: { storage: attributes }, expects: 201
        end
      end

      class Mock
        def templatize_storage(id, attributes)
          storage = find_storage(id)
          attributes = wire(attributes)
          refuse Error, 400, "TITLE_MISSING", "The required attribute title is missing from the request." unless attributes.key?("title")

          template = storage.slice("zone", "size", "tier", "license").merge(
            "uuid" => identifier("01"), "title" => attributes["title"], "access" => "private", "type" => "template",
            "template_type" => "native", "state" => "online", "labels" => [], "created" => now.iso8601
          )
          data[:storages][template["uuid"]] = template
          response 201, "storage" => template
        end
      end
    end
  end
end
