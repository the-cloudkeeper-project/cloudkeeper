require 'tmpdir'
require 'faraday'
require 'zaru'
require 'openssl'
require 'json'

module Cloudkeeper
  module Managers
    class ImageListManager
      attr_reader :image_lists, :openssl_store

      def initialize
        @image_lists = {}

        @openssl_store = OpenSSL::X509::Store.new
        @openssl_store.add_path Cloudkeeper::Settings[:'ca-dir'] if Cloudkeeper::Settings[:'ca-dir']
      end

      def download_image_lists
        Dir.mktmpdir('cloudkeeper') do |dir|
          urls = Cloudkeeper::Settings[:'image-lists']
          retrieve_image_lists urls, dir
        end
      end

      private

      def retrieve_image_lists(urls, dir)
        urls.each do |url|
          begin
            image_list = convert_image_list(load_image_list(download_image_list(url, dir)))
            image_lists[image_list.identifier] = image_list
          rescue Cloudkeeper::Errors::ImageList::RetrievalError, Faraday::ConnectionFailed => ex
            logger.warn "Image list #{url} couldn't be donwloaded\n#{ex.message}"
            next
          end
        end
      end

      def download_image_list(url, dir)
        Cloudkeeper::Utils::Url.check!(url)
        uri = URI.parse url

        filename = generate_filename(uri, dir)
        response = make_request uri

        if response.success?
          File.write filename, response.body
          return filename
        end

        raise Cloudkeeper::Errors::ImageList::RetrievalError,
              "couldn't download image list from url #{url.inspect}\n#{response.to_hash.inspect}"
      end

      def make_request(uri)
        conn = Faraday.new url: uri
        conn.get
      end

      def generate_filename(uri, dir)
        File.join(dir, Zaru.sanitize!("#{uri.host}#{uri.path}"))
      end

      def convert_image_list(image_list_hash)
        Cloudkeeper::Entities::ImageList.from_hash image_list_hash
      end

      def load_image_list(file)
        pkcs7 = OpenSSL::PKCS7.read_smime(File.read(file))
        verify_image_list!(pkcs7, file)

        JSON.parse pkcs7.data
      end

      def verify_image_list!(pkcs7, file)
        raise Cloudkeeper::Errors::ImageList::VerificationError, "image list #{file.inspect} cannot be verified" \
          unless pkcs7.verify([], openssl_store)
      end
    end
  end
end
