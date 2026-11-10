module Fog
  module UpCloud
    class Compute
      # What a storage and an image, a storage template, share. fog keeps
      # attributes per class, so each model declares them through this. size
      # is in GB; tier is maxiops, standard or hdd (UpCloud's archive). A
      # storage is online when ready to use and in maintenance while UpCloud
      # works on it. Public templates and CD-ROMs have no zone.
      module StorageAttributes
        def self.included(model)
          model.class_eval do
            identity :id, aliases: "uuid"

            attribute :title
            attribute :zone
            attribute :size, type: :integer
            attribute :tier
            attribute :type
            attribute :access
            attribute :state
            attribute :labels
            attribute :created
            attribute :template_type
            attribute :origin
            attribute :license, type: :integer
            attribute :encrypted

            def labels=(value)
              attributes[:labels] = Values.labels(value)
            end

            def created=(value)
              attributes[:created] = Values.time(value)
            end
          end
        end

        # Deletes the storage, which mustn't be attached to a server, with its
        # backups
        def destroy
          requires :id
          service.delete_storage(id, backups: "delete")
          true
        end

        def ready?
          state == "online"
        end

        def public?
          access == "public"
        end

        def private?
          access == "private"
        end
      end
    end
  end
end
