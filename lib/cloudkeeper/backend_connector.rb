module Cloudkeeper
  class BackendConnector
    attr_reader :grpc_client, :nginx

    def initialize
      @grpc_client = CloudkeeperGrpc::Communicator::Stub.new(Cloudkeeper::Settings[:'backend-endpoint'], :this_channel_is_insecure)
      @nginx = Cloudkeeper::Nginx::HttpServer.new
    end

    def pre_action
      logger.debug "'pre_action' gRPC method call"
      handle_errors grpc_client.pre_action(Google::Protobuf::Empty.new, return_op: true), raise_exception: true
    end

    def post_action
      logger.debug "'post_action' gRPC method call"
      handle_errors grpc_client.post_action(Google::Protobuf::Empty.new, return_op: true)
    end

    def add_appliance(appliance)
      logger.debug "'add_appliance' gRPC method call"
      manage_appliance appliance, :add_appliance
    end

    def update_appliance(appliance)
      logger.debug "'update_appliance' gRPC method call"
      manage_appliance appliance, :update_appliance
    end

    def remove_appliance(appliance)
      logger.debug "'remove_appliance' gRPC method call"
      manage_appliance appliance, :remove_appliance
    end

    def remove_image_list(image_list_identifier)
      logger.debug "'remove_image_list' gRPC method call"
      handle_errors grpc_client.remove_image_list(
        CloudkeeperGrpc::ImageListIdentifier.new(image_list_identifier: image_list_identifier),
        return_op: true
      )
    end

    def image_lists
      logger.debug "'image_lists' gRPC method call"
      handle_errors(grpc_client.image_lists(Google::Protobuf::Empty.new, return_op: true)) do |response|
        response.map(&:image_list_identifier)
      end
    end

    def appliances(image_list_identifier)
      logger.debug "'appliances' gRPC method call"
      handle_errors(
        grpc_client.appliances(
          CloudkeeperGrpc::ImageListIdentifier.new(image_list_identifier: image_list_identifier),
          return_op: true
        )
      ) do |response|
        response.inject({}) do |acc, elem|
          image = convert_image_proto(elem.image)
          appliance = convert_appliance_proto elem, image
          acc.merge appliance.identifier => appliance
        end
      end
    end

    private

    def handle_errors(operation, raise_exception: false)
      return_value = operation.execute
      return_value = yield(return_value) if block_given?
      check_status operation.trailing_metadata, raise_exception: raise_exception

      return_value
    end

    def check_status(metadata, raise_exception: false)
      return if metadata[CloudkeeperGrpc::Constants::KEY_STATUS] == CloudkeeperGrpc::Constants::STATUS_SUCCESS

      message = "#{metadata[CloudkeeperGrpc::Constants::KEY_STATUS]}: #{metadata[CloudkeeperGrpc::Constants::KEY_MESSAGE]}"
      logger.error "Backend error: #{message}"
      raise Cloudkeeper::Errors::BackendError, message if raise_exception
    end

    def convert_image(image)
      image_file = acceptable_image_file image

      CloudkeeperGrpc::Image.new mode: :LOCAL, location: image_file.file, format: image_file.format.upcase,
                                 checksum: image_file.checksum, size: image.size.to_i, uri: image.uri
    end

    def set_remote_data(image_proto, access_data)
      image_proto.mode = :REMOTE
      image_proto.location = access_data[:url]
      image_proto.username = access_data[:username]
      image_proto.password = access_data[:password]
    end

    def convert_appliance(appliance, image_proto)
      CloudkeeperGrpc::Appliance.new identifier: appliance.identifier.to_s, description: appliance.description.to_s,
                                     mpuri: appliance.mpuri.to_s, title: appliance.title.to_s, group: appliance.group.to_s,
                                     ram: appliance.ram.to_i, core: appliance.core.to_i, version: appliance.version.to_s,
                                     architecture: appliance.architecture.to_s, operating_system: appliance.operating_system.to_s,
                                     vo: appliance.vo.to_s, image: image_proto, expiration_date: appliance.expiration_date.to_i,
                                     image_list_identifier: appliance.image_list_identifier.to_s, attributes: appliance.attributes
    end

    def convert_image_proto(image_proto)
      return nil unless image_proto

      Cloudkeeper::Entities::Image.new image_proto.uri, image_proto.checksum, image_proto.size
    end

    def convert_appliance_proto(appliance_proto, image)
      Cloudkeeper::Entities::Appliance.new appliance_proto.identifier, appliance_proto.mpuri, appliance_proto.vo,
                                           Time.at(appliance_proto.expiration_date).to_datetime,
                                           appliance_proto.image_list_identifier, appliance_proto.title,
                                           appliance_proto.description, appliance_proto.group, appliance_proto.ram,
                                           appliance_proto.core, appliance_proto.version, appliance_proto.architecture,
                                           appliance_proto.operating_system, image, appliance_proto.attributes.to_h
    end

    def acceptable_image_file(image)
      image_format = (image.available_formats & Cloudkeeper::Settings[:formats].map(&:to_sym).sort).first
      unless image_format
        raise Cloudkeeper::Errors::Image::Format::NoRequiredFormatAvailableError, 'image is not available in any of the ' \
                                                                                  'required formats'
      end

      image.image_file image_format
    end

    def prepare_image_proto(image)
      image ? convert_image(image) : nil
    end

    def manage_appliance(appliance, call)
      image = appliance.image
      image_proto = prepare_image_proto image

      if Cloudkeeper::Settings[:'remote-mode'] && image
        nginx.start image_proto.location
        set_remote_data image_proto, nginx.access_data
      end

      handle_errors grpc_client.send(call, convert_appliance(appliance, image_proto), return_op: true)

      nginx.stop if Cloudkeeper::Settings[:'remote-mode'] && image
    rescue Cloudkeeper::Errors::NginxError, Cloudkeeper::Errors::Image::Format::NoRequiredFormatAvailableError => ex
      raise Cloudkeeper::Errors::Appliance::PropagationError, ex
    end
  end
end
