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
                 desc: 'Runs cloudkeeper in debug mode.'

    desc 'sync', 'Runs synchronization process'
    def sync
      # parameters = initialize_action(options, __method__)
    end

    desc 'migrate', 'Discovers and prepares already uploaded appliances'
    def migrate
      # parameters = initialize_action(options, __method__)
    end

    desc 'version', 'Prints cloudkeeper version'
    def version
      $stdout.puts Cloudkeeper::VERSION
    end

    default_task :sync

    private

    def initialize_action(options, action)
      parameters = options.to_hash.deep_symbolize_keys
      initialize_logger parameters
      logger.debug "Cloudkeeper action #{action.inspect} called with parameters: #{parameters.inspect}"

      parameters
    end

    # Inits logging according to the settings
    #
    # @param [Hash] parameters
    # @option parameters [String] logging-level
    # @option parameters [String] logging-file file to log to
    # @option parameters [TrueClass, FalseClass] debug debug mode
    # @return [Type] description of returned object
    def initialize_logger(parameters)
      parameters[:'logging-level'] = 'DEBUG' if parameters[:debug]

      logging_file = parameters[:'logging-file']
      logging_level = parameters[:'logging-level']

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
