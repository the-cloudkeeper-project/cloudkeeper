module Cloudkeeper
  module Errors
    module ImageFormat
      module Ova
        autoload :OvaFormatError, 'cloudkeeper/errors/image_format/ova/ova_format_error'
        autoload :InvalidArchiveError, 'cloudkeeper/errors/image_format/ova/invalid_archive_error'
      end
    end
  end
end
