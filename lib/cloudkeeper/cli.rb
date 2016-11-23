require 'thor'
require 'yell'

module Cloudkeeper
  class CLI < Thor
    class_option :'logging-level',
                 required: true,
                 default: Cloudkeeper::Settings['logging']['level'],
                 type: :string,
                 enum: Yell::Severities
    class_option :'logging-file',
                 default: Cloudkeeper::Settings['logging']['file'],
                 type: :string,
                 desc: 'File to write logs to'
    class_option :debug,
                 default: Cloudkeeper::Settings['debug'],
                 type: :boolean,
                 desc: 'Runs cloudkeeper in debug mode'

    method_option :'qemu-img-binary',
                  default: Cloudkeeper::Settings['binaries']['qemu-img'],
                  type: :string,
                  desc: 'Path to qemu-img binary (image conversion)'
    desc 'sync', 'Runs synchronization process'
    def sync
      initialize_action(options, __method__)
    end

    desc 'migrate', 'Discovers and prepares already uploaded appliances'
    def migrate
      initialize_action(options, __method__)
    end

    desc 'version', 'Prints cloudkeeper version'
    def version
      $stdout.puts Cloudkeeper::VERSION
    end

    default_task :sync

    private

    def initialize_action(options, action)
      initialize_configuration options
      initialize_logger
      logger.debug "Cloudkeeper action #{action.inspect} called with parameters: #{Settings.to_hash.inspect}"
    end

    def initialize_configuration(options)
      Cloudkeeper::Settings.clear
      Cloudkeeper::Settings.merge! options.to_hash
    end

    # Inits logging according to the settings
    #
    # @option parameters [String] logging-level
    # @option parameters [String] logging-file file to log to
    # @option parameters [TrueClass, FalseClass] debug debug mode
    def initialize_logger
      Cloudkeeper::Settings[:'logging-level'] = 'DEBUG' if Cloudkeeper::Settings[:debug]

      logging_file = Cloudkeeper::Settings[:'logging-file']
      logging_level = Cloudkeeper::Settings[:'logging-level']

      Yell.new :stdout, name: Object, level: logging_level.downcase, format: Yell::DefaultFormat
      Object.send :include, Yell::Loggable

      setup_file_logger(logging_file) if logging_file

      logger.debug 'Running in debug mode...'
    end

    def setup_file_logger(logging_file)
      unless (File.exist?(logging_file) && File.writable?(logging_file)) || File.writable?(File.dirname(logging_file))
        logger.error "File #{logging_file} isn't writable"
        return
      end

      logger.adapter :file, logging_file
    end
  end
end
