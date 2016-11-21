module Cloudkeeper
  module Entities
    module Convertables
      module Ova
        include Cloudkeeper::Entities::Convertables::Convertable

        CONVERT_OUTPUT_FORMATS = [:raw, :qcow2].freeze

        def self.extended(base)
          raise Cloudkeeper::Errors::Convertables::ConvertabilityError, "#{base.inspect} cannot become OVA convertable" \
          unless base.respond_to?(:file) && base.respond_to?(:format)

          super
        end

        def to_vmdk
          image_file(extract_disk, :vmdk)
        end

        def to_ova
          self
        end

        private

        def convert_output_formats
          CONVERT_OUTPUT_FORMATS
        end

        def convert(output_format)
          vmdk_image = to_vmdk
          final_image = vmdk_image.send("to_#{output_format.to_s}".to_sym)
          File.delete vmdk_image.file

          final_image
        end

        def extract_disk
          archived_disk = disk_file
          disk_directory = File.dirname(file)
          tar_command = Mixlib::ShellOut.new('tar', '-x', '-f', file, '-C', disk_directory, archived_disk)
          tar_command.run_command

          if tar_command.error?
            raise Cloudkeeper::Errors::CommandExecutionError, "Command #{tar_command.command.inspect} terminated with an error: " \
                                                              "#{tar_command.stderr}"
          end

          File.join(disk_directory, archived_disk)
        end

        def archive_files
          tar_command = Mixlib::ShellOut.new('tar', '-t', '-f', file)
          tar_command.run_command

          if tar_command.error?
            raise Cloudkeeper::Errors::CommandExecutionError, "Command #{tar_command.command.inspect} terminated with an error: " \
                                                              "#{tar_command.stderr}"
          end

          tar_command.stdout.lines.map(&:chomp)
        end

        def disk_file
          archive_files.each { |file| return file if Cloudkeeper::Entities::ImageFormats::Ova::VMDK_REGEX =~ file }
        end
      end
    end
  end
end
