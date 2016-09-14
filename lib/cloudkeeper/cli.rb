require 'thor'
require 'yell'

module Cloudkeeper
  class CLI < Thor
    class_option :debug,
                 default: false,
                 type: :boolean,
                 desc: 'Runs cloud-keeper in debug mode.'

    desc 'sync', 'Runs synchronization process'
    def sync
      initialize_logger options
    end

    desc 'migrate', 'Discovers and prepares already uploaded appliances'
    def migrate
      initialize_logger options
    end

    desc 'version', 'Prints cloud-keeper version'
    def version
      $stdout.puts OnetableTerminator::VERSION
    end

    default_task :sync

    private

    def initialize_logger(parameters)
      logging_level = 'INFO'
      logging_level = 'DEBUG' if parameters[:debug]

      Yell.new :stdout, name: Object, level: logging_level.downcase, format: Yell::DefaultFormat
      Object.send :include, Yell::Loggable

      logger.debug 'Running in debug mode...'
    end
  end
end
