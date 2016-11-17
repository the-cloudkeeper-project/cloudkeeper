module Cloudkeeper
  module Entities
    class Appliance < Struct.new(:identifier, :description, :mpuri, :title,
                                 :group, :ram, :core, :version, :architecture,
                                 :operating_system, :image, :attributes, :vo,
                                 :expiration_date, :image_list_identifier)
      def initialize
        self.attributes = {}
      end

      class << self
        def from_hash(appliance_hash)
          appliance_hash.deep_symbolize_keys!
          check_appliance_hash! appliance_hash

          appliance = populate_appliance appliance_hash

          appliance.image = Image.from_hash(appliance_hash)

          appliance
        end

        def populate_appliance(appliance_hash)
          appliance = Appliance.new
          appliance.identifier = appliance_hash[:'dc:identifier']
          appliance.description = appliance_hash[:'dc:description']
          appliance.mpuri = appliance_hash[:'ad:mpuri']
          appliance.title = appliance_hash[:'dc:title']
          appliance.group = appliance_hash[:'ad:group']
          appliance.ram = appliance_hash[:'ad:ram_recommended']
          appliance.core = appliance_hash[:'ad:core_recommended']
          appliance.version = appliance_hash[:'hv:version']
          appliance.architecture = appliance_hash[:'sl:arch']

          construct_name!(appliance, appliance_hash)
          populate_attributes!(appliance, appliance_hash)

          appliance.vo = appliance_hash[:vo]
          appliance.expiration_date = appliance_hash[:expiration]
          appliance.image_list_identifier = appliance_hash[:image_list_identifier]

          appliance
        end

        def construct_name!(appliance, appliance_hash)
          appliance.operating_system = appliance_hash[:'sl:os'].to_s
          appliance.operating_system = "#{appliance.operating_system} #{appliance_hash[:'sl:osname']}".strip
          appliance.operating_system = "#{appliance.operating_system} #{appliance_hash[:'sl:osversion']}".strip
        end

        def populate_attributes!(appliance, appliance_hash)
          appliance.attributes = appliance_hash.clone
        end

        def check_appliance_hash!(appliance_hash)
          unless Cloudkeeper::Utils::Hash.values? appliance_hash, :'dc:identifier', :'ad:mpuri', :vo, \
                                                  :image_list_identifier
            raise Cloudkeeper::Errors::Parsing::InvalidApplianceHashError, 'appliance hash ' \
              "#{appliance_hash.inspect} doesn't contain all necessary data"
          end
        end
      end
    end
  end
end
