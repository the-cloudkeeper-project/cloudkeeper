module Cloudkeeper
  module Entities
    class Appliance
      attr_accessor :identifier, :description, :mpuri, :title, :group, :ram, :core, :version, :architecture, :operating_system
      attr_accessor :image, :attributes, :vo, :expiration_date, :image_list_identifier

      class << self
        def from_hash(appliance_hash)
          appliance_hash.deep_symbolize_keys!

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
          appliance.operating_system = "#{appliance_hash[:'sl:os']} - #{appliance_hash[:'sl:osname']} \
                                        #{appliance_hash[:'sl:osversion']}"
          appliance.vo = appliance_hash[:vo]
          appliance.expiration_date = appliance_hash[:expiration]
          appliance.image_list_identifier = appliance_hash[:image_list_identifier]

          appliance
        end
      end
    end
  end
end
