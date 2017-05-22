require 'digest'

module Cloudkeeper
  module Entities
    module Convertables
      module Convertable
        CONVERT_OUTPUT_FORMATS = %i[raw qcow2 vmdk vdi].freeze

        def self.included(base)
          raise Cloudkeeper::Errors::Convertables::ConvertabilityError, "#{base.inspect} cannot become a convertable" \
            unless base.method_defined?(:file) && base.method_defined?(:format)

          super
        end

        def convert_output_formats
          CONVERT_OUTPUT_FORMATS
        end

        def format_regex
          /^to_(?<format>#{convert_output_formats.join('|')})$/
        end

        def method_missing(method, *arguments, &block)
          result = method.to_s.match(format_regex)
          if result && result[:format]
            return self if format.to_sym == result[:format].to_sym
            return convert result[:format]
          end

          super
        end

        def respond_to_missing?(method, *)
          method =~ format_regex || super
        end

        private

        def convert(output_format)
          logger.debug "Converting file #{file.inspect} from #{format.inspect} to #{output_format.inspect}"

          converted_file = File.join(File.dirname(file), "#{File.basename(file, '.*')}.#{output_format}")
          run_convert_command(output_format, converted_file)

          image_file converted_file, output_format
        rescue Cloudkeeper::Errors::CommandExecutionError => ex
          delete_if_exists converted_file
          raise ex
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

        def delete_if_exists(file)
          File.delete(file) if File.exist?(file.to_s)
        end
      end
    end
  end
end
