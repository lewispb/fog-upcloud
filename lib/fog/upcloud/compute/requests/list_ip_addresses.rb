module Fog
  module UpCloud
    class Compute
      class Real
        # Every IP address of the account, each with the server it's on
        # ("server", its uuid), access, family and zone: every server's
        # addresses in one request, which the list of servers leaves out
        def list_ip_addresses
          request method: :get, path: "ip_address", expects: 200
        end
      end

      class Mock
        def list_ip_addresses
          addresses = data[:servers].values.flat_map do |server|
            server.dig("ip_addresses", "ip_address").to_a.map { |address| address.merge("server" => server["uuid"], "zone" => server["zone"]) }
          end

          response 200, "ip_addresses" => { "ip_address" => addresses }
        end
      end
    end
  end
end
