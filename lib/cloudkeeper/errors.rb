module Cloudkeeper
  module Errors
    autoload :StandardError, 'cloudkeeper/errors/standard_error'
    autoload :ArgumentError, 'cloudkeeper/errors/argument_error'
    autoload :InvalidURLError, 'cloudkeeper/errors/invalid_url_error'
    autoload :NoSuchFileError, 'cloudkeeper/errors/no_such_file_error'
    autoload :PermissionDeniedError, 'cloudkeeper/errors/permission_denied_error'
    autoload :CommandExecutionError, 'cloudkeeper/errors/command_execution_error'

    autoload :Parsing, 'cloudkeeper/errors/parsing'
    autoload :ImageList, 'cloudkeeper/errors/image_list'
    autoload :ImageFormat, 'cloudkeeper/errors/image_format'
  end
end
