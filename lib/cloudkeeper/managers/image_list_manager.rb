require 'tmpdir'
require 'open-uri'
require 'zaru'
require 'openssl'
require 'json'

module Cloudkeeper
  module Managers
    class ImageListManager
      attr_reader :image_lists, :openssl_store

      def initialize(options = {})
        @image_lists = []

        ca_dir = options[:ca_dir]
        @openssl_store = OpenSSL::X509::Store.new
        @openssl_store.add_path ca_dir if ca_dir
      end

      def download_image_lists(urls)
        Dir.mktmpdir('cloudkeeper') do |dir|
          urls.each do |url|
            image_list_file = download_image_list(url, dir)
            image_list_hash = load_image_list image_list_file
            image_lists << convert_image_list(image_list_hash)
          end
        end
      end

      private

      def download_image_list(url, dir)
        raise InvalidURLError, "#{url.inspect} is not a valid URL" unless url =~ /\A#{URI.regexp(%w(http https))}\z/

        uri = URI.parse url
        user = uri.user
        password = uri.password
        uri.user = nil
        uri.password = nil
        filename = generate_filename(uri, dir)
        download_stream = open(uri, http_basic_authentication: [user, password])
        IO.copy_stream(download_stream, filename)

        filename
      end

      def generate_filename(uri, dir)
        File.join(dir, Zaru.sanitize!("#{uri.host}#{uri.path}"))
      end

      def convert_image_list(image_list_hash)
        Cloudkeeper::Entities::ImageList.from_hash image_list_hash
      end

      def load_image_list(file)
        file_content = File.read file
        pkcs7 = OpenSSL::PKCS7.read_smime file_content
        verify_image_list!(pkcs7, file)

        JSON.parse pkcs7.data
      end

      def verify_image_list!(pkcs7, file)
        raise Cloudkeeper::Errors::ImageListVerificationError,
              "image list #{file.inspect} cannot be verified" unless pkcs7.verify([], openssl_store)
      end
    end
  end
end
