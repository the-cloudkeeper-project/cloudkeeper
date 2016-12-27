module Cloudkeeper
  module Errors
    autoload :StandardError, 'cloudkeeper/errors/standard_error'
    autoload :ArgumentError, 'cloudkeeper/errors/argument_error'
    autoload :NotImplementedError, 'cloudkeeper/errors/not_implemented_error'
    autoload :InvalidURLError, 'cloudkeeper/errors/invalid_url_error'
    autoload :NoSuchFileError, 'cloudkeeper/errors/no_such_file_error'
    autoload :PermissionDeniedError, 'cloudkeeper/errors/permission_denied_error'
    autoload :CommandExecutionError, 'cloudkeeper/errors/command_execution_error'
    autoload :NginxError, 'cloudkeeper/errors/nginx_error'
    autoload :BackendError, 'cloudkeeper/errors/backend_error'
    autoload :InvalidConfigurationError, 'cloudkeeper/errors/invalid_configuration_error'

    autoload :Parsing, 'cloudkeeper/errors/parsing'
    autoload :ImageList, 'cloudkeeper/errors/image_list'
    autoload :ImageFormat, 'cloudkeeper/errors/image_format'
    autoload :Convertables, 'cloudkeeper/errors/convertables'
  end
end
