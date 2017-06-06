module Cloudkeeper
  module Entities
    class ImageFile
      attr_accessor :file, :format, :checksum, :size, :original

      include Cloudkeeper::Entities::Convertables::Convertable

      def initialize(file, format, checksum, size, original = false)
        raise Cloudkeeper::Errors::ArgumentError, 'file, format, checksum and size cannot be nil nor empty'\
          if file.blank? || format.blank? || checksum.blank? || size.blank?

        @file = file
        @format = format
        @checksum = checksum
        @size = size
        @original = original

        format_const_symbol = format.to_s.classify.to_sym
        extend(Cloudkeeper::Entities::Convertables.const_get(format_const_symbol)) \
          if Cloudkeeper::Entities::Convertables.const_defined? format_const_symbol
      end
    end
  end
end
