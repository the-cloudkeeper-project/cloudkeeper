module Cloudkeeper
  module Entities
    class ImageFile
      attr_accessor :file, :checksum, :format, :original

      include Cloudkeeper::Entities::Convertables::Convertable

      def initialize(file, format, checksum, original = false)
        raise Cloudkeeper::Errors::ArgumentError, 'file, format and checksum cannot be nil nor empty'\
          if file.blank? || format.blank? || checksum.blank?

        @file = file
        @checksum = checksum
        @format = format
        @original = original

        format_const_symbol = format.to_s.classify.to_sym
        extend(Cloudkeeper::Entities::Convertables.const_get(format_const_symbol)) \
          if Cloudkeeper::Entities::Convertables.const_defined? format_const_symbol
      end
    end
  end
end
