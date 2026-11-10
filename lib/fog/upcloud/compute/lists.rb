module Fog
  module UpCloud
    class Compute
      # UpCloud wraps each list twice, {"servers" => {"server" => [...]}}, and
      # gives the whole list at once. Collections use list for the items.
      module Lists
        # The items under plural and singular in a list request's body
        def list(request, plural, singular, *arguments, **query)
          public_send(request, *arguments, **query).body.dig(plural, singular) || []
        end
      end
    end
  end
end
