require 'webrick'
require 'tempfile'
require 'securerandom'
require 'erb'
require 'tilt/erb'

module Cloudkeeper
  module Nginx
    class HttpServer
      attr_reader :auth_file, :conf_file, :access_data

      def initialize
        @access_data = {}
      end

      def start(image_file)
        @access_data = {}
        credentials = prepare_credentials
        configuration = prepare_configuration File.dirname(image_file), File.basename(image_file)
        prepare_configuration_file configuration
        fill_access_data credentials, configuration

        Cloudkeeper::CommandExecutioner.execute Cloudkeeper::Settings[:'nginx-binary'], '-c', conf_file.path
      rescue Cloudkeeper::Errors::CommandExecutionError, ::IOError => ex
        stop
        raise Cloudkeeper::Errors::NginxError, ex
      end

      def stop
        if conf_file
          Cloudkeeper::CommandExecutioner.execute Cloudkeeper::Settings[:'nginx-binary'], '-s', 'stop', '-c', conf_file.path
          conf_file.unlink
        end

        auth_file.unlink if auth_file
        @access_data = {}
      rescue Cloudkeeper::Errors::CommandExecutionError, ::IOError => ex
        raise Cloudkeeper::Errors::NginxError, ex
      end

      private

      def fill_access_data(credentials, configuration)
        access_data.merge! credentials
        access_data[:url] = "http://#{configuration[:ip_address]}:#{configuration[:port]}/#{configuration[:image_file]}"
      end

      def prepare_credentials
        username = random_string
        password = random_string

        write_auth_file username, password

        logger.debug("Prepared NGINX authentication file #{auth_file.path.inspect}: "\
                     "username: #{username.inspect}, password: #{password.inspect}")

        { username: username, password: password }
      end

      def write_auth_file(username, password)
        @auth_file = Tempfile.new('cloudkeeper-nginx-auth')
        passwd = WEBrick::HTTPAuth::Htpasswd.new(auth_file.path)
        passwd.set_passwd(nil, username, password)
        passwd.flush
        auth_file.close
      end

      def prepare_configuration_file(configuration)
        conf_content = prepare_configuration_file_content configuration
        write_configuration_file conf_content

        logger.debug("Prepared NGINX configuration file #{conf_file.path.inspect}:\n#{conf_content}")
      end

      def write_configuration_file(content)
        @conf_file = Tempfile.new('cloudkeeper-nginx-conf')

        conf_file.write content
        conf_file.close
      end

      def prepare_configuration_file_content(configuration)
        conf_template = Tilt::ERBTemplate.new(File.join(File.expand_path(File.dirname(__FILE__)), 'templates', 'nginx.conf.erb'))
        conf_template.render(Object.new, configuration)
      end

      def prepare_configuration(root_dir, image_file)
        nginx_configuration = {}
        nginx_configuration[:error_log_file] = Cloudkeeper::Settings[:'nginx-error-log-file']
        nginx_configuration[:access_log_file] = Cloudkeeper::Settings[:'nginx-access-log-file']
        nginx_configuration[:pid_file] = Cloudkeeper::Settings[:'nginx-pid-file']
        nginx_configuration[:auth_file] = auth_file.path
        nginx_configuration[:root_dir] = root_dir
        nginx_configuration[:image_file] = image_file
        nginx_configuration[:ip_address] = Cloudkeeper::Settings[:'nginx-ip-address']
        nginx_configuration[:port] = choose_port

        logger.debug("NGINX configuration: #{nginx_configuration.inspect}")
        nginx_configuration
      end

      def choose_port
        rand(Cloudkeeper::Settings[:'nginx-min-port']..Cloudkeeper::Settings[:'nginx-max-port'])
      end

      def random_string
        SecureRandom.uuid
      end
    end
  end
end
