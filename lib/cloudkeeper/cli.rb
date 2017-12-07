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
    class_option :'lock-file',
                 default: Cloudkeeper::Settings['lock-file'],
                 required: true,
                 type: :string,
                 desc: 'File used to ensure only one running instance of cloudkeeper'
    class_option :debug,
                 default: Cloudkeeper::Settings['debug'],
                 type: :boolean,
                 desc: 'Runs cloudkeeper in debug mode'

    method_option :'image-lists',
                  default: Cloudkeeper::Settings['image-lists'],
                  type: :array,
                  desc: 'List of image lists to sync against'
    method_option :'image-lists-file',
                  default: Cloudkeeper::Settings['image-lists-file'],
                  type: :string,
                  desc: 'File containing list of image lists to sync against'
    method_option :'ca-dir',
                  required: false,
                  default: Cloudkeeper::Settings['ca-dir'],
                  type: :string,
                  desc: 'CA directory'
    method_option :authentication,
                  default: Cloudkeeper::Settings['authentication'],
                  type: :boolean,
                  desc: 'Client <-> server authentication'
    method_option :certificate,
                  required: false,
                  default: Cloudkeeper::Settings['certificate'],
                  type: :string,
                  desc: "Core's host certificate"
    method_option :key,
                  required: false,
                  default: Cloudkeeper::Settings['key'],
                  type: :string,
                  desc: "Core's host key"
    method_option :'image-dir',
                  required: true,
                  default: Cloudkeeper::Settings['image-dir'],
                  type: :string,
                  desc: 'Directory to store images to'
    method_option :'qemu-img-binary',
                  required: true,
                  default: Cloudkeeper::Settings['external-tools']['binaries']['qemu-img'],
                  type: :string,
                  desc: 'Path to qemu-img binary (image conversion)'
    method_option :'nginx-binary',
                  default: Cloudkeeper::Settings['external-tools']['binaries']['nginx'],
                  type: :string,
                  desc: 'Path to nginx binary (HTTP server)'
    method_option :'external-tools-execution-timeout',
                  required: true,
                  default: Cloudkeeper::Settings['external-tools']['execution-timeout'],
                  type: :numeric,
                  desc: 'Timeout for execution of external tools in seconds'
    method_option :'remote-mode',
                  default: Cloudkeeper::Settings['remote-mode'],
                  type: :boolean,
                  desc: 'Remote mode starts HTTP server (NGINX) and serves images to backend via HTTP'
    method_option :'nginx-runtime-dir',
                  default: Cloudkeeper::Settings['nginx']['runtime-dir'],
                  type: :string,
                  desc: 'Runtime directory for NGINX'
    method_option :'nginx-error-log-file',
                  default: Cloudkeeper::Settings['nginx']['error-log-file'],
                  type: :string,
                  desc: 'NGINX error log file'
    method_option :'nginx-access-log-file',
                  default: Cloudkeeper::Settings['nginx']['access-log-file'],
                  type: :string,
                  desc: 'NGINX access log file'
    method_option :'nginx-pid-file',
                  default: Cloudkeeper::Settings['nginx']['pid-file'],
                  type: :string,
                  desc: 'NGINX pid file'
    method_option :'nginx-ip-address',
                  default: Cloudkeeper::Settings['nginx']['ip-address'],
                  type: :string,
                  desc: 'IP address NGINX can listen on'
    method_option :'nginx-port',
                  default: Cloudkeeper::Settings['nginx']['port'],
                  type: :numeric,
                  desc: 'Port NGINX can listen on'
    method_option :'nginx-proxy-ip-address',
                  default: Cloudkeeper::Settings['nginx']['proxy']['ip-address'],
                  type: :string,
                  desc: 'Proxy IP address'
    method_option :'nginx-proxy-port',
                  default: Cloudkeeper::Settings['nginx']['proxy']['port'],
                  type: :numeric,
                  desc: 'Proxy port'
    method_option :'nginx-proxy-ssl',
                  default: Cloudkeeper::Settings['nginx']['proxy']['ssl'],
                  type: :boolean,
                  desc: 'Whether proxy will use SSL connection'
    method_option :'backend-endpoint',
                  required: true,
                  default: Cloudkeeper::Settings['backend']['endpoint'],
                  type: :string,
                  desc: "Backend's gRPC endpoint"
    method_option :'backend-certificate',
                  required: false,
                  default: Cloudkeeper::Settings['backend']['certificate'],
                  type: :string,
                  desc: "Backend's certificate"
    method_option :formats,
                  required: true,
                  default: Cloudkeeper::Settings['formats'],
                  type: :array,
                  desc: 'List of acceptable formats images can be converted to'

    desc 'sync', 'Runs synchronization process'
    def sync
      initialize_sync options
      File.open(Cloudkeeper::Settings[:'lock-file'], File::RDWR | File::CREAT, 0o644) do |file|
        lock = file.flock(File::LOCK_EX | File::LOCK_NB)
        Cloudkeeper::Managers::ApplianceManager.new.synchronize_appliances if lock
        abort 'cloudkeeper instance is already running, quitting' unless lock
      end
    rescue Cloudkeeper::Errors::InvalidConfigurationError => ex
      abort ex.message
    rescue StandardError => ex
      logger.error "Unexpected error: #{ex.message}"
      raise ex
    end

    desc 'version', 'Prints cloudkeeper version'
    def version
      $stdout.puts Cloudkeeper::VERSION
    end

    default_task :sync

    private

    def initialize_sync(options)
      initialize_configuration options
      validate_configuration!
      initialize_logger
      logger.debug "Cloudkeeper 'sync' called with parameters: #{Cloudkeeper::Settings.to_hash.inspect}"
    end

    def initialize_configuration(options)
      Cloudkeeper::Settings.clear
      Cloudkeeper::Settings.merge! options.to_hash
    end

    def validate_configuration!
      validate_configuration_group! %i[authentication],
                                    %i[certificate key backend-certificate],
                                    'Authentication configuration missing'
      validate_configuration_group! %i[remote-mode],
                                    %i[nginx-binary nginx-runtime-dir nginx-error-log-file nginx-access-log-file nginx-pid-file
                                       nginx-ip-address nginx-port],
                                    'NGINX configuration missing'
      validate_configuration_group! %i[remote-mode nginx-proxy-ip-address],
                                    %i[nginx-proxy-port],
                                    'NGINX proxy configuration missing'
      validate_contradictory_options! %i[image-lists image-lists-file], one_required: true
    end

    def validate_configuration_group!(flags, required_options, error_message)
      return unless flags.reduce(true) { |acc, elem| Cloudkeeper::Settings[elem] && acc }

      raise Cloudkeeper::Errors::InvalidConfigurationError, error_message unless all_options_available(required_options)
    end

    def validate_contradictory_options!(flags, options)
      filled = flags.select { |flag| Cloudkeeper::Settings[flag] }
      if filled.count > 1
        raise Cloudkeeper::Errors::InvalidConfigurationError, "Following options cannot be used together: #{filled.join(', ')}"
      end

      return unless options[:one_required]
      raise Cloudkeeper::Errors::InvalidConfigurationError, "One of the options #{flags.join(', ')} required" if filled.empty?
    end

    def all_options_available(required_options)
      required_options.reduce(true) { |acc, elem| Cloudkeeper::Settings[elem] && acc }
    end

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
