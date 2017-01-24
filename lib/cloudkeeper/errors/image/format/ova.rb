module Cloudkeeper
  module Errors
    module Image
      module Format
        module Ova
          autoload :OvaFormatError, 'cloudkeeper/errors/image/format/ova/ova_format_error'
          autoload :InvalidArchiveError, 'cloudkeeper/errors/image/format/ova/invalid_archive_error'
        end
      end
    end
  end
end
