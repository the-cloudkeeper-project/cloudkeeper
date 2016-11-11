require 'rubygems/package'

module Cloudkeeper
  module Entities
    module ImageFormats
      module Ova
        OVF_REGEX = /^.+\.ovf$/i
        VMDK_REGEX = /^.+\.vmdk$/i

        def ova?(filename)
          File.open filename do |file|
            tar = open_archive file
            has_ovf = false
            has_vmdk = false

            tar.each do |entry|
              has_ovf |= OVF_REGEX =~ entry.full_name
              has_vmdk |= VMDK_REGEX =~ entry.full_name
            end

            has_ovf && has_vmdk
          end
        end

        def open_archive(file)
          archive = Gem::Package::TarReader.new file
          archive.rewind

          archive
        end
      end
    end
  end
end
