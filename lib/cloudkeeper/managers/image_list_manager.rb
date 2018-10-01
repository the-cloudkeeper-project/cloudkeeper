require 'tmpdir'
require 'faraday'
require 'openssl'
require 'json'

module Cloudkeeper
  module Managers
    class ImageListManager
      attr_reader :image_list, :openssl_store

      def initialize
        @openssl_store = OpenSSL::X509::Store.new
        @openssl_store.add_path Cloudkeeper::Settings[:'ca-dir'] if Cloudkeeper::Settings[:'ca-dir']
      end

      def download_image_list
        logger.debug 'Downloading fresh image lists...'
        url = Cloudkeeper::Settings[:'image-list']
        Dir.mktmpdir('cloudkeeper') { |dir| retrieve_image_list url, dir }
      rescue Cloudkeeper::Errors::ImageList::DownloadError, Cloudkeeper::Errors::ImageList::VerificationError,
             Cloudkeeper::Errors::Parsing::ParsingError, OpenSSL::PKCS7::PKCS7Error, JSON::ParserError => ex
        raise Cloudkeeper::Errors::ImageList::ImageListError, "Image list #{url.inspect} couldn't be downloaded\n#{ex.message}"
      end

      private

      def retrieve_image_list(url, dir)
        @image_list = convert_image_list(load_image_list(download_image_list_file(url, dir)))
      end

      def download_image_list_file(url, dir)
        logger.debug "Downloading image list from #{url.inspect}"
        Cloudkeeper::Utils::URL.check!(url)
        uri = URI.parse url

        filename = generate_filename(uri, dir)
        response = make_request uri

        if response.success?
          File.write filename, response.body
          return filename
        end

        raise Cloudkeeper::Errors::ImageList::RetrievalError,
              "couldn't download image list from url #{url.inspect}\n#{response.to_hash.inspect}"
      rescue Cloudkeeper::Errors::ImageList::RetrievalError, Cloudkeeper::Errors::InvalidURLError, ::IOError,
             ::Faraday::ClientError => ex
        raise Cloudkeeper::Errors::ImageList::DownloadError, ex
      end

      def make_request(uri)
        ssl = {}
        ssl = { ca_path: Cloudkeeper::Settings[:'ca-dir'], cert_store: OpenSSL::X509::Store.new } if Cloudkeeper::Settings[:'ca-dir']
        conn = Faraday.new url: uri, ssl: ssl
        conn.get
      end

      def generate_filename(uri, dir)
        File.join(dir, Cloudkeeper::Utils::Filename.sanitize("#{uri.host}#{uri.path}"))
      end

      def convert_image_list(image_list_hash)
        Cloudkeeper::Entities::ImageList.from_hash image_list_hash
      end

      def load_image_list(file)
        content = File.read(file)
        pkcs7 = OpenSSL::PKCS7.read_smime(content)
        verify_image_list!(pkcs7, file) if Cloudkeeper::Settings[:'verify-image-lists']

        JSON.parse pkcs7.data
      rescue OpenSSL::PKCS7::PKCS7Error => ex
        raise ex if Cloudkeeper::Settings[:'verify-image-lists']

        JSON.parse content
      end

      def verify_image_list!(pkcs7, file)
        raise Cloudkeeper::Errors::ImageList::VerificationError, "image list #{file.inspect} cannot be verified" \
          unless pkcs7.verify([], openssl_store)
      end
    end
  end
end
