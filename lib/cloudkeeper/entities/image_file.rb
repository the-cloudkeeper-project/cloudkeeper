module Cloudkeeper
  module Entities
    ImageFile = Struct.new(:file, :checksum, :format, :original) do
      include Cloudkeeper::Entities::Convertables::Convertable

      def initialize(*argv)
        super(*argv)

        format_const_symbol = format.to_s.classify.to_sym
        extend(Cloudkeeper::Entities::Convertables.const_get(format_const_symbol)) \
          if Cloudkeeper::Entities::Convertables.const_defined? format_const_symbol
      end
    end
  end
end
