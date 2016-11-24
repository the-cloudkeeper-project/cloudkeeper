module Cloudkeeper
  module Entities
    module ImageFormats
      module Ova
        OVF_REGEX = /^.+\.ovf$/i
        VMDK_REGEX = /^.+\.vmdk$/i
        ARCHIVE_MAX_FILES = 100

        def ova?(archive)
          ova_structure?(archive_files(archive))
        rescue Cloudkeeper::Errors::CommandExecutionError, Cloudkeeper::Errors::ImageFormat::Ova::InvalidArchiveError => ex
          raise Cloudkeeper::Errors::ImageFormat::Ova::OvaFormatError, ex
        end

        def archive_files(archive)
          Cloudkeeper::CommandExecutioner.list_archive archive
        end

        def ova_structure?(files)
          check_count! files
          has_ovf = has_vmdk = false

          files.each do |file|
            has_ovf ||= OVF_REGEX =~ file
            has_vmdk ||= VMDK_REGEX =~ file
            break if has_ovf && has_vmdk
          end

          has_ovf && has_vmdk
        end

        def check_count!(files)
          return unless files.count > ARCHIVE_MAX_FILES

          raise Cloudkeeper::Errors::ImageFormat::Ova::InvalidArchiveError, "Too many files in archive: #{files.count}. "\
                                                                            "Maximum is #{ARCHIVE_MAX_FILES}"
        end
      end
    end
  end
end
