module Fog
  module UpCloud
    class Compute
      class Real
        def list_zones
          request method: :get, path: "zone", expects: 200
        end
      end

      class Mock
        def list_zones
          response 200, "zones" => { "zone" => ZONES }
        end
      end
    end
  end
end
