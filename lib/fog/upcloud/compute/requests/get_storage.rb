module Fog
  module UpCloud
    class Compute
      class Real
        def get_storage(id)
          request method: :get, path: "storage/#{id}", expects: 200
        end
      end

      class Mock
        def get_storage(id)
          response 200, "storage" => find_storage(id)
        end
      end
    end
  end
end
