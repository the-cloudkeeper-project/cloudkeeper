module Cloudkeeper
  module Entities
    class Image < Struct.new(:image_files, :size, :uri, :checksum)
      def initialize
        self.image_files = []
      end

      def self.from_hash(image_hash)
        image_hash.deep_symbolize_keys!
        check_image_hash! image_hash

        image = Image.new
        image.size = image_hash[:'hv:size']
        image.uri = image_hash[:'hv:uri']
        image.checksum = image_hash[:'sl:checksum:sha512']

        image
      end

      def self.check_image_hash!(image_hash)
        raise Cloudkeeper::Errors::InvalidImageHashError, "image hash #{image_hash.inspect} doesn't contain all necessary data" \
        unless Cloudkeeper::Utils::Hash.values? image_hash, :'sl:checksum:sha512', :'hv:uri'
      end
    end
  end
end
