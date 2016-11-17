module Cloudkeeper
  module Errors
    module ImageFormat
      autoload :Ova, 'cloudkeeper/errors/image_format/ova'
      autoload :NoFormatRecognizedError, 'cloudkeeper/errors/image_format/no_format_recognized_error'
      autoload :RecognitionError, 'cloudkeeper/errors/image_format/recognition_error'
    end
  end
end
