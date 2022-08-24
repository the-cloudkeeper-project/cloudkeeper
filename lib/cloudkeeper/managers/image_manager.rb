require 'net/https'
require 'digest'

module Cloudkeeper
  module Managers
    class ImageManager
      extend Cloudkeeper::Entities::ImageFormats::Ova

      FORMATS = {
        qcow2: /qemu qcow image/i,
        ova: /posix tar archive/i,
        vmdk: /vmware4 disk image/i,
        raw: /boot sector/i,
        vdi: /virtual(box)? disk image/i
      }.freeze

      class << self
        def format(file)
          check_file!(file)
          recognize_format(file)
        rescue Cloudkeeper::Errors::CommandExecutionError, Cloudkeeper::Errors::NoSuchFileError,
               Cloudkeeper::Errors::PermissionDeniedError, Cloudkeeper::Errors::Image::Format::NoFormatRecognizedError,
               Cloudkeeper::Errors::Image::Format::Ova::OvaFormatError => ex
          raise Cloudkeeper::Errors::Image::Format::RecognitionError, ex, "Cannot recognize image format for file #{file.inspect}"
        end

        def file_description(file)
          Cloudkeeper::CommandExecutioner.execute('file', '-b', file)
        end

        def check_file!(file)
          raise Cloudkeeper::Errors::NoSuchFileError, "No such file #{file.inspect}" unless File.exist?(file)
          raise Cloudkeeper::Errors::PermissionDeniedError, "Cannot read file #{file.inspect}" unless File.readable?(file)
        end

        def recognize_format(file)
          file_format_string = file_description(file)
          FORMATS.each do |format, regex|
            next unless regex =~ file_format_string

            format_test_method = "#{format}?".to_sym
            additional_test_result = respond_to?(format_test_method) ? send(format_test_method, file) : true

            return format if additional_test_result
          end

          raise Cloudkeeper::Errors::Image::Format::NoFormatRecognizedError, "No image format recognized for file #{file.inspect}"
        end

        def secure_download_image(url, checksum)
          logger.debug "Downloading image from #{url.inspect}"
          Cloudkeeper::Utils::URL.check!(url)

          uri = URI.parse url
          filename = generate_filename(uri)
          retrieve_image(uri, filename)
          check_image_checksum!(filename, checksum)

          Cloudkeeper::Entities::ImageFile.new filename, format(filename), Cloudkeeper::Utils::Checksum.compute(filename),
                                               File.size(filename)
        rescue Cloudkeeper::Errors::InvalidURLError, Cloudkeeper::Errors::Image::Format::RecognitionError,
               Cloudkeeper::Errors::ArgumentError, Cloudkeeper::Errors::NetworkConnectionError, ::IOError => ex
          raise Cloudkeeper::Errors::Image::DownloadError, "Image #{url.inspect} download error: #{ex.message}"
        end

        def check_image_checksum!(filename, checksum)
          computed = Digest::SHA512.file(filename).hexdigest
          raise Cloudkeeper::Errors::Image::ChecksumError, "Checksum mismatch, expecting #{checksum.inspect} got #{computed.inspect}" \
            unless checksum == computed
        end

        def retrieve_image(uri, filename)
          Net::HTTP.start(uri.host, uri.port, connection_options(uri)) do |http|
            request = Net::HTTP::Get.new(uri)

            http.request(request) do |response|
              if response.is_a? Net::HTTPRedirection
                retrieve_image URI.join(uri, response.header['location']), filename
                break
              end

              response.value
              File.open(filename, 'w') { |file| response.read_body { |chunk| file.write(chunk) } }
            end
          end
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, Net::HTTPBadResponse,
               Net::HTTPHeaderSyntaxError, EOFError, Net::HTTPServerException, Net::HTTPRetriableError,
               Net::HTTPFatalError, OpenSSL::SSL::SSLError => ex
          raise Cloudkeeper::Errors::NetworkConnectionError, ex
        end

        def connection_options(uri)
          use_ssl = uri.scheme == 'https'
          ca_path = Cloudkeeper::Settings[:'ca-dir'] if Cloudkeeper::Settings[:'ca-dir']
          { use_ssl: use_ssl, ca_path: ca_path }
        end

        def generate_filename(uri)
          File.join(Cloudkeeper::Settings[:'image-dir'], Cloudkeeper::Utils::Filename.sanitize(File.basename(uri.path)))
        end
      end
    end
  end
end
