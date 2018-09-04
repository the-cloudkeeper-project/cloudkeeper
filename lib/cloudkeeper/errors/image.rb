module Cloudkeeper
  module Errors
    module Image
      autoload :Format, 'cloudkeeper/errors/image/format'
      autoload :DownloadError, 'cloudkeeper/errors/image/download_error'
      autoload :ChecksumError, 'cloudkeeper/errors/image/checksum_error'
      autoload :ConversionError, 'cloudkeeper/errors/image/conversion_error'
    end
  end
end
