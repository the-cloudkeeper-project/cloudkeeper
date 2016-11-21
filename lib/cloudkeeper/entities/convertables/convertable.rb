require 'digest'

module Cloudkeeper
  module Entities
    module Convertables
      module Convertable
        CONVERT_OUTPUT_FORMATS = [:raw, :qcow2, :vmdk].freeze

        def method_missing(method, *arguments, &block)
          result = method.to_s.match(/^to_(?<format>.*)$/)
          return convert(result[:format]) if result[:format] && convert_output_formats.include?(result[:format].to_sym)

          super
        end

        def to_ova
          raise NotImplementedError, 'converison to OVA format is not supported'
        end

        private

        def convert_output_formats
          CONVERT_OUTPUT_FORMATS
        end

        def convert(output_format)
          return self if output_format.to_sym == format.to_sym

          converted_file = File.join(File.dirname(file), "#{File.basename(file, '.*')}.#{output_format.to_s}")
          convert_command = Mixlib::ShellOut.new(Cloudkeeper::Settings[:'qemu-img-binary'], 'convert', '-f', format.to_s, '-O', output_format.to_s, file, converted_file)
          convert_command.run_command

          if convert_command.error?
            raise Cloudkeeper::Errors::CommandExecutionError, "Command #{convert_command.command.inspect} terminated with an error: " \
                                                              "#{convert_command.stderr}"
          end

          image_file converted_file, output_format
        end

        def image_file(converted_file, output_format)
          Cloudkeeper::Entities::ImageFile.new converted_file, compute_checksum(converted_file), output_format, false
        end

        def compute_checksum(converted_file)
          Digest::SHA512.file(converted_file).hexdigest
        end
      end
    end
  end
end
