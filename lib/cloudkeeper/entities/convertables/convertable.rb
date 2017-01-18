require 'digest'

module Cloudkeeper
  module Entities
    module Convertables
      module Convertable
        CONVERT_OUTPUT_FORMATS = [:raw, :qcow2, :vmdk].freeze

        def self.convert_output_formats
          CONVERT_OUTPUT_FORMATS
        end

        FORMAT_REGEX = /^to_(?<format>#{convert_output_formats.join('|')})$/

        def self.included(base)
          raise Cloudkeeper::Errors::Convertables::ConvertabilityError, "#{base.inspect} cannot become a convertable" \
            unless base.method_defined?(:file) && base.method_defined?(:format)

          super
        end

        def method_missing(method, *arguments, &block)
          result = method.to_s.match(FORMAT_REGEX)
          return convert(result[:format]) if result && result[:format]

          super
        end

        def respond_to_missing?(method, *)
          method =~ FORMAT_REGEX || super
        end

        private

        def convert(output_format)
          return self if output_format.to_sym == format.to_sym

          converted_file = File.join(File.dirname(file), "#{File.basename(file, '.*')}.#{output_format}")
          run_convert_command(output_format, converted_file)

          image_file converted_file, output_format
        end

        def run_convert_command(output_format, converted_file)
          Cloudkeeper::CommandExecutioner.execute(Cloudkeeper::Settings[:'qemu-img-binary'],
                                                  'convert',
                                                  '-f',
                                                  format.to_s,
                                                  '-O',
                                                  output_format.to_s,
                                                  file,
                                                  converted_file)
        end

        def image_file(converted_file, output_format)
          Cloudkeeper::Entities::ImageFile.new converted_file, output_format.to_sym,
                                               Cloudkeeper::Utils::Checksum.compute(converted_file), false
        end
      end
    end
  end
end
