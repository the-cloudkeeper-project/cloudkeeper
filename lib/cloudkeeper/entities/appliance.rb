require 'digest'
require 'json'

module Cloudkeeper
  module Entities
    class Appliance
      IMAGE_LIST_APPLIANCE_ATTRIBUTES = %i[dc:identifier ad:mpuri dc:date:expires dc:title dc:description
                                           ad:group hv:ram_minimum hv:core_minimum hv:version sl:arch
                                           ad:base_mpuri ad:appid sl:os sl:osname sl:osversion].freeze

      attr_accessor :identifier, :description, :mpuri, :title, :group, :ram, :core, :version, :architecture
      attr_accessor :operating_system, :image, :vo, :expiration_date, :image_list_identifier, :base_mpuri, :appid, :digest

      def initialize(identifier, mpuri, vo, expiration_date, image_list_identifier, title = '', description = '', group = '',
                     ram = 1024, core = 1, version = '', architecture = '', base_mpuri = '', appid = '', digest = '',
                     operating_system = '', image = nil)
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
        @vo = vo
        @expiration_date = expiration_date
        @image_list_identifier = image_list_identifier
        @base_mpuri = base_mpuri
        @appid = appid
        @digest = digest
      end

      def expired?
        expiration_date < Time.now
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

          appliance = construct_appliance(appliance_hash)
          construct_os_name!(appliance, appliance_hash)
          compute_digest!(appliance, appliance_hash)

          appliance
        rescue Cloudkeeper::Errors::ArgumentError => ex
          raise Cloudkeeper::Errors::Parsing::InvalidApplianceHashError, ex, "appliance hash #{appliance_hash.inspect} " \
                                                                             "doesn't contain all the necessary data"
        end

        def construct_appliance(appliance_hash)
          Appliance.new appliance_hash[:'dc:identifier'],
                        appliance_hash[:'ad:mpuri'],
                        appliance_hash[:vo],
                        Cloudkeeper::Utils::Date.parse(appliance_hash[:'dc:date:expires']),
                        appliance_hash[:image_list_identifier],
                        appliance_hash[:'dc:title'],
                        appliance_hash[:'dc:description'],
                        appliance_hash[:'ad:group'],
                        appliance_hash[:'hv:ram_minimum'],
                        appliance_hash[:'hv:core_minimum'],
                        appliance_hash[:'hv:version'],
                        appliance_hash[:'sl:arch'],
                        appliance_hash[:'ad:base_mpuri'],
                        appliance_hash[:'ad:appid']
        end

        def construct_os_name!(appliance, appliance_hash)
          appliance.operating_system = appliance_hash[:'sl:os'].to_s
          appliance.operating_system = "#{appliance.operating_system} #{appliance_hash[:'sl:osname']}".strip
          appliance.operating_system = "#{appliance.operating_system} #{appliance_hash[:'sl:osversion']}".strip
        end

        def compute_digest!(appliance, appliance_hash)
          digest_hash = appliance_hash.select { |key| IMAGE_LIST_APPLIANCE_ATTRIBUTES.include? key }
          appliance.digest = Digest::SHA512.hexdigest(digest_hash.to_json)
        end
      end
    end
  end
end
