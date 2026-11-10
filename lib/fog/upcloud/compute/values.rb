module Fog
  module UpCloud
    class Compute
      # Turns UpCloud's shapes into plain Ruby ones for the models, and back.
      module Values
        extend self

        # Labels as a Hash of key => value, from a server's
        # {"label" => [{"key", "value"}]}, a storage's bare list of the same,
        # or a Hash
        def labels(value)
          blocks = value.is_a?(Hash) && value["label"].is_a?(Array) ? value["label"] : value

          if blocks.is_a?(Hash)
            blocks.to_h { |key, label| [ key.to_s, label.to_s ] }
          else
            Array(blocks).to_h { |block| [ block["key"], block["value"] ] }
          end
        end

        # A Hash of labels as the blocks UpCloud takes
        def label_blocks(labels)
          labels.to_h.map { |key, value| { key: key.to_s, value: value.to_s } }
        end

        # A firewall rule's attributes as the block UpCloud takes: symbol or
        # string keys, and numbers as the strings it wants
        def rule_block(rule)
          rule.to_h.to_h { |key, value| [ key.to_sym, value.is_a?(Integer) ? value.to_s : value ] }.compact
        end

        # The items of a wrapped list, {"ip_address" => [...]}, or a bare one
        def items(value, key)
          value.is_a?(Hash) ? Array(value[key]) : Array(value)
        end

        # A time from a storage's ISO 8601 string or a server's seconds since
        # the epoch
        def time(value)
          case value
          when nil, "" then nil
          when Integer then ::Time.at(value).utc
          when ::Time then value
          else ::Time.parse(value.to_s)
          end
        end

        # A list request's query from label filters: label: "env=ci" (or a
        # key alone, or an Array of either) and labels: { "env" => "ci" }.
        # Every label given must match.
        def query(filters)
          filters = filters.dup
          labels = Array(filters.delete(:label)) + filters.delete(:labels).to_h.map { |key, value| "#{key}=#{value}" }
          filters.merge(label: labels.empty? ? nil : labels).compact
        end
      end
    end
  end
end
