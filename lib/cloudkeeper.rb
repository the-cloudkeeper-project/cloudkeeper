require 'active_support/all'
require 'mixlib/shellout'

module Cloudkeeper
  autoload :Settings, 'cloudkeeper/settings'
  autoload :CLI, 'cloudkeeper/cli'
  autoload :Utils, 'cloudkeeper/utils'
  autoload :Nginx, 'cloudkeeper/nginx'
  autoload :CommandExecutioner, 'cloudkeeper/command_executioner'
  autoload :Entities, 'cloudkeeper/entities'
  autoload :Managers, 'cloudkeeper/managers'
  autoload :BackendConnector, 'cloudkeeper/backend_connector'
  autoload :Errors, 'cloudkeeper/errors'
end

require 'cloudkeeper/version'
