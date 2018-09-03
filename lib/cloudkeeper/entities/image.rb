require 'digest'
require 'json'

module Cloudkeeper
  module Entities
    class Image
      IMAGE_LIST_IMAGE_ATTRIBUTES = %i[hv:uri sl:checksum:sha512 hv:size hv:version].freeze

      attr_accessor :image_files, :size, :uri, :checksum, :digest

      def initialize(uri, checksum, size = 0, digest = '', image_files = [])
        raise Cloudkeeper::Errors::ArgumentError, 'uri and checksum cannot be nil nor empty' if uri.blank? || checksum.blank?

        @uri = uri
        @checksum = checksum
        @size = size
        @digest = digest
        @image_files = image_files
      end

      def add_image_file(file)
        raise Cloudkeeper::Errors::ArgumentError, 'image file cannot be nil' if file.nil?

        image_files << file
      end

      def available_formats
        image_files.map(&:format).sort
      end

      def image_file(format)
        image_files.select { |file| file.format == format }.first
      end

      def self.from_hash(image_hash)
        raise Cloudkeeper::Errors::Parsing::InvalidImageHashError, 'invalid image hash' if image_hash.blank?

        image_hash.deep_symbolize_keys!
        image_hash.keep_if { |key| IMAGE_LIST_IMAGE_ATTRIBUTES.include? key }

        Image.new image_hash[:'hv:uri'], image_hash[:'sl:checksum:sha512'], image_hash[:'hv:size'],
                  Digest::SHA512.hexdigest(image_hash.to_json)
      rescue Cloudkeeper::Errors::ArgumentError => ex
        raise Cloudkeeper::Errors::Parsing::InvalidImageHashError, ex, "image hash #{image_hash.inspect} " \
                                                                       "doesn't contain all the necessary data"
      end
    end
  end
end
