require 'digest'

module Cloudkeeper
  module Entities
    module Convertables
      module Convertable
        CONVERT_OUTPUT_FORMATS = [:raw, :qcow2, :vmdk].freeze
        FORMAT_REGEX = /^to_(?<format>.*)$/

        def self.included(base)
          raise Cloudkeeper::Errors::Convertables::ConvertabilityError, "#{base.inspect} cannot become a convertable" \
            unless base.method_defined?(:file) && base.method_defined?(:format)

          super
        end

        def method_missing(method, *arguments, &block)
          result = method.to_s.match(FORMAT_REGEX)
          return convert(result[:format]) if result && result[:format] && convert_output_formats.include?(result[:format].to_sym)

          super
        end

        def respond_to_missing?(method, *)
          method =~ FORMAT_REGEX || super
        end

        def to_ova
          raise Cloudkeeper::Errors::NotImplementedError, 'converison to OVA format is not supported'
        end

        private

        def convert_output_formats
          CONVERT_OUTPUT_FORMATS
        end

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
          Cloudkeeper::Entities::ImageFile.new converted_file, output_format.to_sym, compute_checksum(converted_file), false
        end

        def compute_checksum(converted_file)
          Digest::SHA512.file(converted_file).hexdigest
        end
      end
    end
  end
end
