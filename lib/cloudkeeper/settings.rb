require 'settingslogic'

module Cloudkeeper
  class Settings < Settingslogic
    CONFIGURATION = 'cloudkeeper.yml'.freeze

    # three possible configuration file locations in order by preference
    # if configuration file is found rest of the locations are ignored
    source "#{ENV['HOME']}/.cloudkeeper/#{CONFIGURATION}"\
    if File.exist?("#{ENV['HOME']}/.cloudkeeper/#{CONFIGURATION}")

    source "/etc/cloudkeeper/#{CONFIGURATION}"\
    if File.exist?("/etc/cloudkeeper/#{CONFIGURATION}")

    source "#{File.dirname(__FILE__)}/../../config/#{CONFIGURATION}"

    namespace 'cloudkeeper'
  end
end
