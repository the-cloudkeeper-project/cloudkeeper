module Cloudkeeper
  module Entities
    class Appliance
      attr_accessor :identifier, :description, :mpuri, :title, :group, :ram, :core, :version, :architecture
      attr_accessor :operating_system, :image, :attributes, :vo, :expiration_date, :image_list_identifier

      REJECTED_ATTRIBUTES = %i[vo expiration image_list_identifier].freeze

      def initialize(identifier, mpuri, vo, expiration_date, image_list_identifier, title = '', description = '', group = '',
                     ram = 1024, core = 1, version = '', architecture = '', operating_system = '', image = nil, attributes = {})
        if identifier.blank? || \
           mpuri.blank? || \
           vo.blank? || \
           expiration_date.blank? || \
           image_list_identifier.blank?
          raise Cloudkeeper::Errors::ArgumentError, 'identifier, mpuri, vo, expiration_date and image_list_identifier ' \
                                                    'cannot be nil nor empty'
        end

        @identifier = identifier
        @description = description
        @mpuri = mpuri
        @title = title
        @group = group
        @ram = ram
        @core = core
        @version = version
        @architecture = architecture
        @operating_system = operating_system
        @image = image
        @attributes = attributes
        @vo = vo
        @expiration_date = expiration_date
        @image_list_identifier = image_list_identifier
      end

      class << self
        def from_hash(appliance_hash)
          appliance_hash.deep_symbolize_keys!
          appliance = populate_appliance appliance_hash
          appliance.image = Image.from_hash(appliance_hash)

          appliance
        end

        def populate_appliance(appliance_hash)
          raise Cloudkeeper::Errors::Parsing::InvalidApplianceHashError, 'invalid appliance hash' if appliance_hash.blank?

          appliance = Appliance.new appliance_hash[:'dc:identifier'],
                                    appliance_hash[:'ad:mpuri'],
                                    appliance_hash[:vo],
                                    appliance_hash[:expiration],
                                    appliance_hash[:image_list_identifier],
                                    appliance_hash[:'dc:title'],
                                    appliance_hash[:'dc:description'],
                                    appliance_hash[:'ad:group'],
                                    appliance_hash[:'hv:ram_minimum'],
                                    appliance_hash[:'hv:core_minimum'],
                                    appliance_hash[:'hv:version'],
                                    appliance_hash[:'sl:arch']

          construct_os_name!(appliance, appliance_hash)
          populate_attributes!(appliance, appliance_hash)

          appliance
        rescue Cloudkeeper::Errors::ArgumentError => ex
          raise Cloudkeeper::Errors::Parsing::InvalidApplianceHashError, ex, "appliance hash #{appliance_hash.inspect} " \
                                                                             "doesn't contain all the necessary data"
        end

        def construct_os_name!(appliance, appliance_hash)
          appliance.operating_system = appliance_hash[:'sl:os'].to_s
          appliance.operating_system = "#{appliance.operating_system} #{appliance_hash[:'sl:osname']}".strip
          appliance.operating_system = "#{appliance.operating_system} #{appliance_hash[:'sl:osversion']}".strip
        end

        def populate_attributes!(appliance, appliance_hash)
          appliance_hash.reject! { |k, _v| REJECTED_ATTRIBUTES.include? k }
          appliance.attributes = appliance_hash.map { |k, v| [k.to_s, v.to_s] }.to_h
        end
      end
    end
  end
end
