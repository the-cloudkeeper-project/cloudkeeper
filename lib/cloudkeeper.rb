require 'active_support/all'

module Cloudkeeper
  autoload :Version, 'cloudkeeper/version'
  autoload :Settings, 'cloudkeeper/settings'
  autoload :CLI, 'cloudkeeper/cli'
  autoload :Utils, 'cloudkeeper/utils'
  autoload :Entities, 'cloudkeeper/entities'
  autoload :Managers, 'cloudkeeper/managers'
  autoload :Errors, 'cloudkeeper/errors'
end
