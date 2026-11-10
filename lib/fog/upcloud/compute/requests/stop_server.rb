module Fog
  module UpCloud
    class Compute
      class Real
        # Stops a started server: stop_type "soft" (an ACPI signal, and a hard
        # stop after timeout seconds if one's given) or "hard".
        def stop_server(id, attributes = {})
          request method: :post, path: "server/#{id}/stop", body: { stop_server: attributes }, expects: [ 200, 202 ]
        end
      end

      class Mock
        def stop_server(id, attributes = {})
          server = find_server(id)
          refuse Error, 409, "SERVER_STATE_ILLEGAL", "The server is in a state in which it cannot be used." unless server["state"] == "started"

          server["state"] = "stopped"
          response 200, "server" => server
        end
      end
    end
  end
end
