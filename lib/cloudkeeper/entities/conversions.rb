module Cloudkeeper
  module Entities
    module Conversions
      private

      def convert_image(image)
        image_file = acceptable_image_file image

        CloudkeeperGrpc::Image.new mode: :LOCAL, location: image_file.file, format: image_file.format.upcase,
                                   checksum: image_file.checksum, size: image.size.to_i, uri: image.uri
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
    end
  end
end
