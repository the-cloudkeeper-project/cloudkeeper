require 'date'

module Cloudkeeper
  module Entities
    class ImageList
      attr_accessor :identifier, :creation_date, :expiration_date, :description, :title, :source, :appliances

      DATE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'.freeze

      def initialize(identifier, expiration_date, creation_date = nil, source = '', title = '', description = '', appliances = {})
        raise Cloudkeeper::Errors::ArgumentError, 'identifier cannot be nil nor empty' if identifier.blank? || expiration_date.blank?

        @identifier = identifier
        @expiration_date = expiration_date
        @creation_date = creation_date
        @description = description
        @title = title
        @source = source
        @appliances = appliances
      end

      def add_appliance(appliance)
        raise Cloudkeeper::Errors::ArgumentError, 'appliance cannot be nil' unless appliance

        appliances[appliance.identifier] = appliance
      end

      def expired?
        expiration_date < DateTime.now
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
          raise Cloudkeeper::Errors::Parsing::InvalidImageListHashError, 'invalid image list hash' if image_list_hash.blank?

          ImageList.new image_list_hash[:'dc:identifier'],
                        parse_date(image_list_hash[:'dc:date:expires']),
                        parse_date(image_list_hash[:'dc:date:created']),
                        image_list_hash[:'dc:source'],
                        image_list_hash[:'dc:title'],
                        image_list_hash[:'dc:description']
        rescue Cloudkeeper::Errors::ArgumentError => ex
          raise Cloudkeeper::Errors::Parsing::InvalidImageListHashError, ex, "image list hash #{image_list_hash.inspect} " \
                                                                             "doesn't contain all the necessary data"
        end

        def parse_date(date)
          date.blank? ? '' : DateTime.strptime(date, DATE_FORMAT)
        end

        def populate_appliances!(image_list, image_list_hash)
          expiration = parse_date(image_list_hash[:'dc:date:expires'])
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
