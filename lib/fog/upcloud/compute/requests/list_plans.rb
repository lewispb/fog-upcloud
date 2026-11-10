module Fog
  module UpCloud
    class Compute
      class Real
        def list_plans
          request method: :get, path: "plan", expects: 200
        end
      end

      class Mock
        def list_plans
          response 200, "plans" => { "plan" => PLANS }
        end
      end
    end
  end
end
