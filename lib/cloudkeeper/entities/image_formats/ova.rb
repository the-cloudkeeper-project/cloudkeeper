require 'rubygems/package'

module Cloudkeeper
  module Entities
    module ImageFormats
      module Ova
        OVF_REGEX = /^.+\.ovf$/i
        VMDK_REGEX = /^.+\.vmdk$/i
        ARCHIVE_MAX_FILES = 100

        def ova?(archive)
          ova_structure?(archive_files(archive))
        end

        def archive_files(archive)
          tar_command = Mixlib::ShellOut.new('tar', '-t', '-f', archive)
          tar_command.run_command

          if tar_command.error?
            raise Cloudkeeper::Errors::CommandExecutionError, "Command #{tar_command.command.inspect} terminated with an error: " \
                                                              "#{tar_command.stderr}"
          end

          tar_command.stdout.lines.map(&:chomp)
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

          raise Cloudkeeper::Errors::InvalidArchiveError, "Too many files in archive: #{files.count}. Maximum is #{ARCHIVE_MAX_FILES}"
        end
      end
    end
  end
end
