module Cloudkeeper
  module Entities
    class Image
      attr_accessor :image_files, :size, :uri, :checksum

      def self.from_hash(image_hash)
        image_hash.deep_symbolize_keys!

        image = Image.new
        image.size = image_hash[:'hv:size']
        image.uri = image_hash[:'hv:uri']
        image.checksum = image_hash[:'sl:checksum:sha512']

        image
      end
    end
  end
end
