require "fog/compute/models/server"

module Fog
  module UpCloud
    class Compute
      # A server. It's created in a zone on a plan, with its disk cloned from
      # a template (a storage template's id), a public IPv4 address and a
      # utility one unless interfaces says otherwise, and UpCloud's metadata
      # service on, which cloud-init templates need.
      #
      #   server = compute.servers.create(
      #     zone: "de-fra1", plan: "2xCPU-4GB", template: image.id, hostname: "ci-1",
      #     storage_size: 50, labels: { "role" => "ci" }, ssh_keys: [ public_key ], user_data: "#cloud-config\n"
      #   )
      #   server.wait_for { ready? }
      #
      # Labels are a Hash of key => value. Cloud-init templates, such as
      # Ubuntu's, need at least one of ssh_keys, which are installed for
      # username (root unless it's given).
      class Server < Fog::Compute::Server
        INTERFACES = [ { type: "public", family: "IPv4" }, { type: "utility", family: "IPv4" } ]
        STOP_TIMEOUT = 300
        STOP_INTERVAL = 5

        identity :id, aliases: "uuid"

        attribute :title
        attribute :hostname
        attribute :zone
        attribute :plan
        attribute :state
        attribute :labels
        attribute :created
        attribute :ip_addresses
        attribute :storage_devices
        attribute :core_number, type: :integer
        attribute :memory_amount, type: :integer
        attribute :firewall
        attribute :password

        attribute :template
        attribute :storage_size, type: :integer
        attribute :storage_tier
        attribute :interfaces
        attribute :ssh_keys, type: :array
        attribute :user_data

        def labels=(value)
          attributes[:labels] = Values.labels(value)
        end

        def created=(value)
          attributes[:created] = Values.time(value)
        end

        # Each address as {"access" => "public", "family" => "IPv4", "address" => ...}
        def ip_addresses=(value)
          attributes[:ip_addresses] = Values.items(value, "ip_address")
        end

        def storage_devices=(value)
          attributes[:storage_devices] = Values.items(value, "storage_device")
        end

        # Whether the server's firewall rules apply: true, false, or nil
        # for UpCloud's default, on
        def firewall=(value)
          attributes[:firewall] = value.nil? ? nil : [ true, "on" ].include?(value)
        end

        def save
          raise Fog::Errors::Error, "Resaving an existing object may create a duplicate" if persisted?

          requires :zone, :plan, :hostname, :template
          merge_attributes service.create_server(creation_attributes).body.fetch("server")
          true
        end

        # Stops the server hard if it isn't stopped, waits up to timeout
        # seconds for UpCloud to report it stopped, then deletes it with its
        # storages and their backups. A server that's already gone is
        # destroyed too.
        def destroy(timeout: STOP_TIMEOUT, interval: STOP_INTERVAL)
          requires :id
          stop_hard_and_wait timeout, interval
          service.delete_server(id, storages: 1, backups: "delete")
          true
        rescue NotFound
          true
        end

        def start
          requires :id
          merge_attributes service.start_server(id, start_type: "async").body.fetch("server")
          true
        end

        # Stops the server: soft, an ACPI signal with a hard stop after
        # timeout seconds, or hard, at once.
        def stop(type: "soft", timeout: 60)
          requires :id
          merge_attributes service.stop_server(id, stop_type: type, timeout: timeout.to_s).body.fetch("server")
          true
        end

        # Replaces the server's labels with labels, a Hash of key => value
        def update_labels(labels)
          requires :id
          merge_attributes service.update_server(id, labels: { label: Values.label_blocks(labels) }).body.fetch("server")
          true
        end

        def firewall_rules
          requires :id
          service.firewall_rules(id)
        end

        def ready?
          state == "started"
        end

        def stopped?
          state == "stopped"
        end

        def public_ip_address
          address_of "public"
        end

        def private_ip_address
          address_of "utility"
        end

        private
          def creation_attributes
            {
              zone: zone, plan: plan, hostname: hostname, title: title || hostname, metadata: "yes",
              firewall: { true => "on", false => "off" }[firewall], labels: { label: Values.label_blocks(labels) },
              networking: { interfaces: { interface: (interfaces || INTERFACES).map { |interface| interface_block(interface) } } },
              storage_devices: { storage_device: [ disk ] }, login_user: login_user, user_data: user_data
            }.compact
          end

          def interface_block(interface)
            interface = interface.transform_keys(&:to_sym)
            { type: interface.fetch(:type), network: interface[:network], ip_addresses: { ip_address: [ { family: interface.fetch(:family, "IPv4") } ] } }.compact
          end

          def disk
            { action: "clone", storage: template, title: hostname, size: storage_size, tier: storage_tier }.compact
          end

          def login_user
            { username: username, create_password: "no", ssh_keys: { ssh_key: ssh_keys } }.compact if ssh_keys&.any?
          end

          def address_of(access)
            ip_addresses.to_a.find { |address| address["access"] == access && address["family"] == "IPv4" }&.fetch("address")
          end

          # UpCloud stops a started server only; one in maintenance, still
          # being created or changed, is waited on until it's started or
          # stopped
          def stop_hard_and_wait(timeout, interval)
            Fog.wait_for(timeout, interval) do
              merge_attributes service.get_server(id).body.fetch("server")
              stop_hard if ready?
              stopped?
            end
          end

          def stop_hard
            stop type: "hard"
          rescue Error => error
            raise unless error.code == "SERVER_STATE_ILLEGAL"
          end
      end
    end
  end
end
