module Cloudkeeper
  module Managers
    class ImageManager
      FORMATS = {
        qcow2: /qemu qcow image/i,
        ova: /posix tar archive/i,
        vmdk: /vmware4 disk image/i,
        raw: /boot sector/i
      }.freeze

      class << self
        def format(file)
          check_file!(file)
          recognize_format(file_description(file))
        rescue Cloudkeeper::Errors::CommandExecutionError, Cloudkeeper::Errors::NoSuchFileError,
               Cloudkeeper::Errors::PermissionDeniedError, Cloudkeeper::Errors::NoImageFormatRecognizedError => ex
          raise Cloudkeeper::Errors::ImageFormatRecognitionError, ex, "Cannot recognize image format for file #{file.inspect}"
        end

        def file_description(file)
          file_command = Mixlib::ShellOut.new('file', '-b', file)
          file_command.run_command

          if file_command.error?
            raise Cloudkeeper::Errors::CommandExecutionError, "Command #{file_command.command.inspect} terminated with an error: " \
                                                              "#{file_command.stderr}"
          end

          file_command.stdout
        end

        def check_file!(file)
          raise Cloudkeeper::Errors::NoSuchFileError, "No such file #{file.inspect}" unless File.exist?(file)
          raise Cloudkeeper::Errors::PermissionDeniedError, "Cannot read file #{file.inspect}" unless File.readable?(file)
        end

        def recognize_format(file_format_string)
          FORMATS.each { |format, regex| return format if regex =~ file_format_string }

          raise Cloudkeeper::Errors::NoImageFormatRecognizedError, 'No image format recognizes from file description ' \
                                                                   "#{file_format_string.inspect}"
        end
      end
    end
  end
end
