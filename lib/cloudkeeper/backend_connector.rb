module Cloudkeeper
  class BackendConnector
    attr_reader :grpc_client, :nginx

    def initialize
      @grpc_client = Cloudkeeper::Grpc::Communicator::Stub.new(Cloudkeeper::Settings[:'backend-endpoint'], :this_channel_is_insecure)
      @nginx = Cloudkeeper::Nginx::HttpServer.new
    end

    def pre_action
      check_status grpc_client.pre_action(Google::Protobuf::Empty.new)
    end

    def post_action
      check_status grpc_client.post_action(Google::Protobuf::Empty.new)
    end

    def add_appliance(appliance)
      manage_appliance appliance, :add_appliance
    end

    def update_appliance(appliance)
      manage_appliance appliance, :update_appliance
    end

    def remove_appliance(appliance)
      manage_appliance appliance, :remove_appliance
    end

    def remove_image_list(image_list_identifier)
      check_status grpc_client.remove_image_list(
        Cloudkeeper::Grpc::ImageListIdentifier.new(image_list_identifier: image_list_identifier)
      )
    end

    def image_lists
      response = grpc_client.image_lists(Google::Protobuf::Empty.new)
      response.map(&:image_list_identifier)
    end

    def appliances(image_list_identifier)
      response = grpc_client.appliances(Cloudkeeper::Grpc::ImageListIdentifier.new(image_list_identifier: image_list_identifier))
      response.map do |appliance_proto|
        image = convert_image_proto(appliance_proto.image)
        convert_appliance_proto appliance_proto, image
      end
    end

    private

    def check_status(status)
      raise Cloudkeeper::Errors::BackendError, "error: #{status.code}\n#{status.message}" unless status.code == :SUCCESS
    end

    def convert_image(image)
      image_file = acceptable_image_file image

      Cloudkeeper::Grpc::Image.new mode: :LOCAL, location: image_file.file, format: image_file.format.upcase,
                                   checksum: image_file.checksum, size: image.size, uri: image.uri
    end

    def set_remote_data(image_proto, access_data)
      image_proto.mode = :REMOTE
      image_proto.location = access_data[:url]
      image_proto.username = access_data[:username]
      image_proto.password = access_data[:password]
    end

    def convert_appliance(appliance, image_proto)
      Cloudkeeper::Grpc::Appliance.new identifier: appliance.identifier, description: appliance.description,
                                       mpuri: appliance.mpuri, title: appliance.title, group: appliance.group,
                                       ram: appliance.ram, core: appliance.core, version: appliance.version,
                                       architecture: appliance.architecture, operating_system: appliance.operating_system,
                                       vo: appliance.vo, image: image_proto, expiration_date: appliance.expiration_date.to_i,
                                       image_list_identifier: appliance.image_list_identifier, attributes: appliance.attributes
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
      raise Cloudkeeper::Errors::ImageFormat::NoRequiredFormatAvailableError, 'image is not available in any of the required formats' \
        unless image_format

      image.image_file image_format
    end

    def manage_appliance(appliance, call)
      image = appliance.image

      image_proto = image ? convert_image(image) : nil
      appliance_proto = convert_appliance(appliance, image_proto)

      if Cloudkeeper::Settings[:'remote-mode'] && image
        nginx.start image_proto.location
        set_remote_data image_proto, nginx.access_data
      end

      status = grpc_client.send(call, appliance_proto)

      nginx.stop if Cloudkeeper::Settings[:'remote-mode'] && image

      check_status status
    end
  end
end
