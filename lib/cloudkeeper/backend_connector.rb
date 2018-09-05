module Cloudkeeper
  class BackendConnector
    include Cloudkeeper::Entities::Conversions

    attr_reader :grpc_client, :nginx, :errors

    def initialize
      @grpc_client = CloudkeeperGrpc::Communicator::Stub.new(Cloudkeeper::Settings[:'backend-endpoint'], credentials)
      @nginx = Cloudkeeper::Nginx::HttpServer.new
      @errors = false
    end

    def pre_action
      logger.debug "'pre_action' gRPC method call"
      handle_errors(exception: true) { grpc_client.pre_action(Google::Protobuf::Empty.new) }
    end

    def post_action
      logger.debug "'post_action' gRPC method call"
      handle_errors { grpc_client.post_action(Google::Protobuf::Empty.new) }
    end

    def add_appliance(appliance)
      logger.debug "'add_appliance' gRPC method call (appliance.identifier: #{appliance.identifier})"
      manage_appliance appliance, :add_appliance
    end

    def update_appliance(appliance)
      logger.debug "'update_appliance' gRPC method call (appliance.identifier: #{appliance.identifier})"
      manage_appliance appliance, :update_appliance
    end

    def update_appliance_metadata(appliance)
      logger.debug "'update_appliance_metadata' gRPC method call (appliance.identifier: #{appliance.identifier})"
      appliance.image = nil
      manage_appliance appliance, :update_appliance_metadata
    end

    def remove_appliance(appliance)
      logger.debug "'remove_appliance' gRPC method call (appliance.identifier: #{appliance.identifier})"
      appliance.image = nil
      manage_appliance appliance, :remove_appliance
    end

    def remove_image_list(image_list_identifier)
      logger.debug "'remove_image_list' gRPC method call (image_list_identifier: #{image_list_identifier})"
      handle_errors do
        grpc_client.remove_image_list(CloudkeeperGrpc::ImageListIdentifier.new(image_list_identifier: image_list_identifier))
      end
    end

    def image_lists
      logger.debug "'image_lists' gRPC method call"
      response = handle_errors(exception: true) { grpc_client.image_lists(Google::Protobuf::Empty.new) }
      response.map(&:image_list_identifier)
    end

    def appliances(image_list_identifier)
      logger.debug "'appliances' gRPC method call"
      response = handle_errors(exception: true) do
        grpc_client.appliances(CloudkeeperGrpc::ImageListIdentifier.new(image_list_identifier: image_list_identifier))
      end

      response.inject({}) do |acc, elem|
        image = convert_image_proto(elem.image)
        appliance = convert_appliance_proto elem, image
        acc.merge appliance.identifier => appliance
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

    def handle_errors(exception: false, default: Google::Protobuf::Empty.new)
      raise Cloudkeeper::Errors::ArgumentError, 'Backend connector error-wrapper was called without a block!' unless block_given?

      yield
    rescue GRPC::BadStatus => ex
      errors = CloudkeeperGrpc::Constants.constants.reduce({}) { |acc, el| acc.merge(CloudkeeperGrpc::Constants.const_get(el) => el) }
      message = "#{errors[ex.code]}: #{ex.details}"
      logger.error "Backend error: #{message}"
      @errors = true
      raise Cloudkeeper::Errors::BackendError, message if exception
      default
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

      handle_errors { grpc_client.send(call, convert_appliance(appliance, image_proto)) }

      nginx.stop if Cloudkeeper::Settings[:'remote-mode'] && image
    rescue Cloudkeeper::Errors::NginxError, Cloudkeeper::Errors::Image::Format::NoRequiredFormatAvailableError => ex
      raise Cloudkeeper::Errors::Appliance::PropagationError, ex
    end
  end
end
