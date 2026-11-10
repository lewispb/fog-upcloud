module Fog
  module UpCloud
    class Compute
      class Real
        def get_server(id)
          request method: :get, path: "server/#{id}", expects: 200
        end
      end

      class Mock
        def get_server(id)
          response 200, "server" => find_server(id)
        end
      end
    end
  end
end
