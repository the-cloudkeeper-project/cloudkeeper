require 'tmpdir'
require 'open-uri'
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
        urls = Cloudkeeper::Settings[:'image-lists']
        Dir.mktmpdir('cloudkeeper') do |dir|
          urls.each do |url|
            image_list_hash = load_image_list(download_image_list(url, dir))
            image_list = convert_image_list(image_list_hash)
            image_lists[image_list.identifier] = image_list
          end
        end
      end

      private

      def download_image_list(url, dir)
        Cloudkeeper::Utils::Url.check!(url)

        uri = URI.parse url
        user = uri.user
        password = uri.password
        uri.user = nil
        uri.password = nil
        filename = generate_filename(uri, dir)
        IO.copy_stream(open(uri, http_basic_authentication: [user, password]), filename)

        filename
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
