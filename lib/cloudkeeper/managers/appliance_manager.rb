module Cloudkeeper
  module Managers
    class ApplianceManager
      include Cloudkeeper::Utils::Appliance

      attr_reader :backend_connector, :image_list_manager, :acceptable_formats

      def initialize
        @backend_connector = Cloudkeeper::BackendConnector.new
        @image_list_manager = Cloudkeeper::Managers::ImageListManager.new
        @acceptable_formats = Cloudkeeper::Settings[:formats].map(&:to_sym)
      end

      def synchronize_appliances
        logger.debug 'Running appliance synchronization...'
        backend_connector.pre_action

        backend_image_lists = backend_connector.image_lists
        image_list_manager.download_image_lists

        sync_new_image_lists(backend_image_lists)
        sync_old_image_lists(backend_image_lists)

        backend_connector.post_action
      rescue Cloudkeeper::Errors::BackendError => ex
        abort ex.message
      end

      def errors
        { backend_errors: backend_connector.errors, image_list_errors: image_list_manager.errors }
      end

      private

      def sync_new_image_lists(backend_image_lists)
        logger.debug 'Registering appliances from new image lists...'
        add_list = image_list_manager.image_lists.keys - backend_image_lists
        logger.debug "Image lists to register: #{add_list.inspect}"
        add_list.each do |image_list_identifier|
          image_list = image_list_manager.image_lists[image_list_identifier]

          if image_list.expired?
            log_expired image_list, 'Skipping expired image list'
            next
          end

          add_new_appliances image_list
        end
      end

      def add_new_appliances(image_list)
        image_list.appliances.each_value do |appliance|
          if appliance.expired?
            log_expired appliance, 'Skipping expired appliance'
            next
          end

          add_appliance appliance
        end
      end

      def sync_old_image_lists(backend_image_lists)
        logger.debug 'Synchronizing registered appliances...'
        sync_list = image_list_manager.image_lists.keys & backend_image_lists
        logger.debug "Image lists to synchronize: #{sync_list.inspect}"
        sync_list.each { |image_list_identifier| sync_image_list image_list_identifier }
      end

      def sync_image_list(image_list_identifier)
        image_list = image_list_manager.image_lists[image_list_identifier]

        if image_list.expired?
          remove_expired_image_list image_list
          return
        end

        logger.debug "Synchronizing appliances for image list with id #{image_list_identifier.inspect}"
        backend_appliances = backend_connector.appliances image_list_identifier
        image_list_appliances = image_list.appliances

        remove_appliances backend_appliances, image_list_appliances
        add_appliances backend_appliances, image_list_appliances
        update_appliances backend_appliances, image_list_appliances
      end

      def remove_expired_image_list(image_list)
        logger.debug "Removing expired image list #{image_list.identifier.inspect}"
        backend_connector.remove_image_list image_list.identifier
      end

      def remove_appliances(backend_appliances, image_list_appliances)
        logger.debug 'Removing previously registered appliances...'
        remove_list = backend_appliances.keys - image_list_appliances.keys
        logger.debug "Appliances to remove: #{remove_list.inspect}"
        remove_list.each { |appliance_identifier| backend_connector.remove_appliance backend_appliances[appliance_identifier] }
      end

      def add_appliances(backend_appliances, image_list_appliances)
        logger.debug 'Registering new appliances...'
        add_list = image_list_appliances.keys - backend_appliances.keys
        logger.debug "Appliances to register: #{add_list.inspect}"
        add_list.each do |appliance_identifier|
          appliance = image_list_appliances[appliance_identifier]
          if appliance.expired?
            log_expired appliance, 'Skipping expired appliance'
            next
          end

          add_appliance appliance
        end
      end

      def update_appliances(backend_appliances, image_list_appliances)
        logger.debug 'Updating appliances...'
        update_list = backend_appliances.keys & image_list_appliances.keys
        logger.debug "Appliances for potential update: #{update_list.inspect}"
        update_list.each do |appliance_identifier|
          image_list_appliance = image_list_appliances[appliance_identifier]
          backend_appliance = backend_appliances[appliance_identifier]

          if image_list_appliance.expired?
            log_expired image_list_appliance, 'Removing expired appliance'
            backend_connector.remove_appliance image_list_appliance
            next
          end

          method = :update_appliance_metadata if update_metadata?(image_list_appliance, backend_appliance)
          method = :update_appliance if update_image?(image_list_appliance, backend_appliance)

          send method, image_list_appliance if method
        end
      end

      def update_appliance(appliance)
        modify_appliance :update_appliance, appliance
      end

      def update_appliance_metadata(appliance)
        appliance.image = nil
        modify_appliance :update_appliance_metadata, appliance
      end

      def add_appliance(appliance)
        modify_appliance :add_appliance, appliance
      end

      def modify_appliance(method, appliance)
        prepare_image!(appliance) if appliance.image
        backend_connector.send method, appliance
      rescue Cloudkeeper::Errors::Image::DownloadError, Cloudkeeper::Errors::Image::ConversionError => ex
        logger.error "Image preparation error: #{ex.message}"
      rescue Cloudkeeper::Errors::Appliance::PropagationError => ex
        logger.error "Appliance propagation error: #{ex.message}"
      ensure
        clean_image_files appliance
      end
    end
  end
end
