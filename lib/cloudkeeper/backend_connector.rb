module Cloudkeeper
  class BackendConnector
    include Cloudkeeper::Entities::Conversions

    attr_reader :grpc_client, :nginx

    def initialize
      @grpc_client = CloudkeeperGrpc::Communicator::Stub.new(Cloudkeeper::Settings[:'backend-endpoint'], credentials)
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

    def credentials
      return :this_channel_is_insecure unless Cloudkeeper::Settings[:authentication]

      GRPC::Core::ChannelCredentials.new(
        File.read(Cloudkeeper::Settings[:'backend-certificate']),
        File.read(Cloudkeeper::Settings[:key]),
        File.read(Cloudkeeper::Settings[:certificate])
      )
    end

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

    def set_remote_data(image_proto, access_data)
      image_proto.mode = :REMOTE
      image_proto.location = access_data[:url]
      image_proto.username = access_data[:username]
      image_proto.password = access_data[:password]
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
