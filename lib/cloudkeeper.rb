require 'active_support/all'
require 'mixlib/shellout'

module Cloudkeeper
  autoload :Version, 'cloudkeeper/version'
  autoload :Settings, 'cloudkeeper/settings'
  autoload :CLI, 'cloudkeeper/cli'
  autoload :Utils, 'cloudkeeper/utils'
  autoload :Nginx, 'cloudkeeper/nginx'
  autoload :CommandExecutioner, 'cloudkeeper/command_executioner'
  autoload :Entities, 'cloudkeeper/entities'
  autoload :Managers, 'cloudkeeper/managers'
  autoload :Errors, 'cloudkeeper/errors'
end
