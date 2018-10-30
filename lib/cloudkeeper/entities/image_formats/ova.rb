module Cloudkeeper
  module Entities
    module ImageFormats
      module Ova
        OVF_REGEX = /^.+\.ovf$/i.freeze
        VMDK_REGEX = /^.+\.vmdk$/i.freeze
        ARCHIVE_MAX_FILES = 100

        def ova?(archive)
          ova_structure?(archive_files(archive))
        rescue Cloudkeeper::Errors::CommandExecutionError, Cloudkeeper::Errors::Image::Format::Ova::InvalidArchiveError => ex
          raise Cloudkeeper::Errors::Image::Format::Ova::OvaFormatError, ex
        end

        def archive_files(archive)
          Cloudkeeper::CommandExecutioner.list_archive archive
        end

        def ova_structure?(files)
          check_file_count! files

          vmdk_count = files.select { |file| VMDK_REGEX =~ file }.count
          ovf_count = files.select { |file| OVF_REGEX =~ file }.count

          raise Cloudkeeper::Errors::Image::Format::Ova::InvalidArchiveError, 'Archive contains multiple drives (VMDK files)' \
            if vmdk_count > 1
          raise Cloudkeeper::Errors::Image::Format::Ova::InvalidArchiveError, 'Archive contains multiple descriptors (OVF files)' \
            if ovf_count > 1

          vmdk_count == 1 && ovf_count == 1
        end

        def check_file_count!(files)
          return unless files.count > ARCHIVE_MAX_FILES

          raise Cloudkeeper::Errors::Image::Format::Ova::InvalidArchiveError, "Too many files in archive: #{files.count}. "\
                                                                            "Maximum is #{ARCHIVE_MAX_FILES}"
        end
      end
    end
  end
end
