module Cloudkeeper
  module Errors
    module Image
      module Format
        autoload :Ova, 'cloudkeeper/errors/image/format/ova'
        autoload :NoFormatRecognizedError, 'cloudkeeper/errors/image/format/no_format_recognized_error'
        autoload :RecognitionError, 'cloudkeeper/errors/image/format/recognition_error'
        autoload :NoRequiredFormatAvailableError, 'cloudkeeper/errors/image/format/no_required_format_available_error'
      end
    end
  end
end
