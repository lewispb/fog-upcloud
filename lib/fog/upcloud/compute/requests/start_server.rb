module Fog
  module UpCloud
    class Compute
      class Real
        # Starts a stopped server. UpCloud returns once the server is started,
        # unless start_type is "async".
        def start_server(id, attributes = {})
          request method: :post, path: "server/#{id}/start", body: { server: attributes }, expects: [ 200, 202 ]
        end
      end

      class Mock
        def start_server(id, attributes = {})
          server = find_server(id)
          refuse Error, 409, "SERVER_STATE_ILLEGAL", "The server is in a state in which it cannot be used." unless server["state"] == "stopped"

          server["state"] = "started"
          response 200, "server" => server
        end
      end
    end
  end
end
