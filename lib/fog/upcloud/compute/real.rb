module Fog
  module UpCloud
    class Compute
      # Talks to UpCloud's API with an API token (Bearer) or a username and
      # password (Basic). A request UpCloud rate limits (429) is retried after
      # each of retry_delays, whatever its method, since UpCloud turned it away
      # unprocessed. A 5xx or a dropped connection is retried the same way for
      # GET, PUT and DELETE only, so a create is never sent twice. Any other
      # error status raises Fog::UpCloud::Compute::NotFound (404) or
      # Fog::UpCloud::Compute::Error, with UpCloud's error_code and message and
      # without Excon's error, whose dump has the response's headers, as its
      # cause.
      class Real
        include Lists

        URL = "https://api.upcloud.com"
        RETRY_DELAYS = [ 1, 2, 4 ]
        IDEMPOTENT = [ :get, :put, :delete ]
        RETRIED = [ Excon::Error::TooManyRequests, Excon::Error::Server, Excon::Error::Socket, Excon::Error::Timeout ]

        def initialize(options = {})
          @authorization = authorization_from(options)
          @retry_delays = options.fetch(:retry_delays, RETRY_DELAYS)
          @connection = Fog::Core::Connection.new(
            options.fetch(:upcloud_url, URL), options.fetch(:persistent, false), options.fetch(:connection_options, {})
          )
        end

        def request(method:, path:, expects:, query: nil, body: nil)
          with_retries(method) do
            decode @connection.request(
              method: method, path: "/1.3/#{path}", query: query, expects: expects, headers: headers,
              body: body && Fog::JSON.encode(body)
            )
          end
        rescue Excon::Error::HTTPStatus => error
          raise error_for(error.response), cause: nil
        end

        def reload
          @connection.reset
        end

        private
          # fog turns settings that look like numbers into Integers, so a
          # username or password is made a String again
          def authorization_from(options)
            if options[:upcloud_token]
              "Bearer #{options[:upcloud_token]}"
            else
              "Basic #{[ "#{options.fetch(:upcloud_username)}:#{options.fetch(:upcloud_password)}" ].pack("m0")}"
            end
          end

          def headers
            {
              "Authorization" => @authorization,
              "Accept" => "application/json",
              "Content-Type" => "application/json",
              "User-Agent" => "fog-upcloud/#{VERSION} fog-core/#{Fog::Core::VERSION}"
            }
          end

          def with_retries(method)
            delays = @retry_delays.dup

            begin
              yield
            rescue *RETRIED => error
              raise unless retried?(method, error) && (delay = delays.shift)

              sleep delay
              retry
            end
          end

          def retried?(method, error)
            error.is_a?(Excon::Error::TooManyRequests) || IDEMPOTENT.include?(method)
          end

          def decode(response)
            response.body = Fog::JSON.decode(response.body) unless response.body.to_s.empty?
            response
          end

          def error_for(response)
            code, description = error_in(response.body)
            message = "#{response.status} #{description}".strip
            response.status == 404 ? NotFound.new(message, code) : Error.new(message, code)
          end

          # UpCloud's {"error" => {"error_code", "error_message"}}, or the
          # body as it is when it isn't that
          def error_in(body)
            error = Fog::JSON.decode(body).fetch("error")
            [ error["error_code"], "#{error["error_code"]} #{error["error_message"]}" ]
          rescue Fog::JSON::DecodeError, KeyError, NoMethodError, TypeError
            [ nil, body ]
          end
      end
    end
  end
end
