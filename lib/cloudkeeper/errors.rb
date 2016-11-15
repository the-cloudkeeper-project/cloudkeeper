module Cloudkeeper
  module Errors
    autoload :StandardError, 'cloudkeeper/errors/standard_error'
    autoload :ArgumentError, 'cloudkeeper/errors/argument_error'
    autoload :ImageListVerificationError, 'cloudkeeper/errors/image_list_verification_error'
    autoload :InvalidImageHashError, 'cloudkeeper/errors/invalid_image_hash_error'
    autoload :InvalidApplianceHashError, 'cloudkeeper/errors/invalid_appliance_hash_error'
    autoload :InvalidURLError, 'cloudkeeper/errors/invalid_url_error'
    autoload :CommandExecutionError, 'cloudkeeper/errors/command_execution_error'
    autoload :NoImageFormatRecognizedError, 'cloudkeeper/errors/no_image_format_recognized_error'
    autoload :NoSuchFileError, 'cloudkeeper/errors/no_such_file_error'
    autoload :PermissionDeniedError, 'cloudkeeper/errors/permission_denied_error'
    autoload :ImageFormatRecognitionError, 'cloudkeeper/errors/image_format_recognition_error'
    autoload :InvalidArchiveError, 'cloudkeeper/errors/invalid_archive_error'
  end
end
