require 'date'

module Cloudkeeper
  module Entities
    class ImageList < Struct.new(:identifier, :creation_date, :description,
                                 :title, :source, :appliances)

      DATE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'.freeze

      def initialize
        self.appliances = []
      end

      def add_appliance(appliance)
        raise Cloudkeeper::Errors::ArgumentError, 'appliance cannot be nil' unless appliance

        appliances << appliance
      end

      class << self
        def from_hash(image_list_hash)
          image_list_hash.deep_symbolize_keys!
          image_list_hash = image_list_hash[:'hv:imagelist']

          image_list = populate_image_list image_list_hash
          populate_appliances!(image_list, image_list_hash)

          image_list
        end

        def prepare_appliance_hash(image_hash, endorser, expiration, vo, image_list_identifier)
          appliance_hash = {}

          appliance_hash = image_hash[:'hv:image'] if image_hash && image_hash.key?(:'hv:image')
          appliance_hash.merge!(vo: vo, expiration: expiration, image_list_identifier: image_list_identifier)
          appliance_hash.merge!(endorser[:'hv:x509']) if endorser && endorser.key?(:'hv:x509')

          appliance_hash
        end

        def populate_image_list(image_list_hash)
          image_list = ImageList.new
          return image_list unless image_list_hash

          image_list.identifier = image_list_hash[:'dc:identifier']
          image_list.creation_date = DateTime.strptime(image_list_hash[:'dc:date:created'], DATE_FORMAT)
          image_list.description = image_list_hash[:'dc:description']
          image_list.source = image_list_hash[:'dc:source']
          image_list.title = image_list_hash[:'dc:title']

          image_list
        end

        def populate_appliances!(image_list, image_list_hash)
          expiration = DateTime.strptime(image_list_hash[:'dc:date:expires'], DATE_FORMAT)
          vo = image_list_hash[:'ad:vo']
          endorser = image_list_hash[:'hv:endorser']

          image_list_hash[:'hv:images'].each do |image_hash|
            appliance = Appliance.from_hash(prepare_appliance_hash(image_hash, endorser, expiration, vo, image_list.identifier))
            image_list.add_appliance appliance
          end
        end
      end
    end
  end
end
