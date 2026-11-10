module Fog
  module UpCloud
    class Compute
      class Real
        # Changes a server from the attributes of UpCloud's server block, such
        # as title, hostname, firewall ("on" or "off") and labels, which
        # replace the server's own. A server in maintenance, still being
        # created or changed, can't be changed.
        def update_server(id, attributes)
          request method: :put, path: "server/#{id}", body: { server: attributes }, expects: 202
        end
      end

      class Mock
        def update_server(id, attributes)
          server = find_server(id)
          refuse Error, 409, "SERVER_STATE_ILLEGAL", "The server is in a state in which it cannot be used." if server["state"] == "maintenance"

          server.merge!(wire(attributes).slice("title", "hostname", "firewall", "labels"))
          response 202, "server" => server
        end
      end
    end
  end
end
