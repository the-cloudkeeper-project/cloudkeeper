require 'digest'

module Cloudkeeper
  module Entities
    module Convertables
      module Convertable
        SUPPORTED_OUTPUT_FORMATS = [:raw, :qcow2, :vmdk].freeze

        def self.extended(base)
          raise Cloudkeeper::Errors::Convertables::ConvertabilityError, "#{base.inspect} cannot become convertable" \
            unless base.respond_to?(:file) && base.respond_to?(:format)

          super
        end

        def self.method_missing(method, *arguments, &block)
          result = method.to_s.match(/^to_(?<format>.*)$/)
          if result[:format] && SUPPORTED_OUTPUT_FORMATS.include?(result[:format])
            convert(result[:format])
            return
          end

          super
        end

        def to_ova
          raise NotImplementedError, 'converison to OVA format is not supported'
        end

        private

        def convert(output_format)
          converted_file = File.join(File.dirname(file), File.basename(file, '.*'), '.raw')
          convert_command = Mixlib::ShellOut.new(Settings[:'qemu-img-binary'], 'convert', '-f', format.to_s, '-O', output_format.to_s, file, converted_file)
          convert_command.run_command

          if convert_command.error?
            raise Cloudkeeper::Errors::CommandExecutionError, "Command #{convert_command.command.inspect} terminated with an error: " \
                                                              "#{convert_command.stderr}"
          end

          image_file converted_file, output_format
        end

        def image_file(converted_file, output_format)
          Cloudkeeper::Entities::ImageFile.new file: converted_file, checksum: checksum(converted_file), format: output_format, original: false
        end

        def checksum(converted_file)
          Digest::SHA512.file(converted_file).hexdigest
        end
      end
    end
  end
end
