require 'spec_helper'

describe Cloudkeeper::Nginx::HttpServer do
  subject(:http_server) { described_class.new }

  describe '#new' do
    it 'returns an instance of HttpServer' do
      is_expected.to be_instance_of described_class
    end

    it 'prepares acces_data attribute as an instance of Hash' do
      expect(http_server.access_data).to be_instance_of Hash
    end

    it 'prepares acces_data attribute as an empty Hash' do
      expect(http_server.access_data).to be_empty
    end
  end

  describe '.random_string' do
    it 'each time returns randomly generated string' do
      string1 = http_server.send(:random_string)
      string2 = http_server.send(:random_string)
      string3 = http_server.send(:random_string)

      expect(string1).not_to eq(string2)
      expect(string1).not_to eq(string3)
      expect(string2).not_to eq(string3)
    end
  end

  describe '.choose_port' do
    before do
      Cloudkeeper::Settings[:'nginx-min-port'] = 100
      Cloudkeeper::Settings[:'nginx-max-port'] = 500
    end

    it 'returns a port number from within the set range' do
      port1 = http_server.send(:choose_port)
      port2 = http_server.send(:choose_port)
      port3 = http_server.send(:choose_port)

      expect(port1).to be >= 100
      expect(port2).to be >= 100
      expect(port3).to be >= 100
      expect(port1).to be <= 500
      expect(port2).to be <= 500
      expect(port3).to be <= 500
    end
  end

  describe '.prepare_configuration' do
    let(:root_dir) { '/cloudkeeper/images' }
    let(:image_file) { 'image.ext' }
    let(:auth_file) { Tempfile.new('cloudkeeper-nginx-spec') }

    before do
      Cloudkeeper::Settings[:'nginx-error-log-file'] = '/nginx/error.log'
      Cloudkeeper::Settings[:'nginx-access-log-file'] = '/nginx/access.log'
      Cloudkeeper::Settings[:'nginx-pid-file'] = '/nginx/nginx.pid'
      Cloudkeeper::Settings[:'nginx-ip-address'] = '127.0.0.1'
      Cloudkeeper::Settings[:'nginx-min-port'] = 100
      Cloudkeeper::Settings[:'nginx-max-port'] = 500
      http_server.instance_variable_set(:@auth_file, auth_file)
    end

    after do
      auth_file.unlink
    end

    it 'returns hash containing NGINX configuration' do
      conf = http_server.send(:prepare_configuration, root_dir, image_file)

      expect(conf[:error_log_file]).to eq('/nginx/error.log')
      expect(conf[:access_log_file]).to eq('/nginx/access.log')
      expect(conf[:pid_file]).to eq('/nginx/nginx.pid')
      expect(conf[:auth_file]).to eq(auth_file.path)
      expect(conf[:root_dir]).to eq(root_dir)
      expect(conf[:image_file]).to eq(image_file)
      expect(conf[:ip_address]).to eq('127.0.0.1')
      expect(conf[:port]).to be >= 100
      expect(conf[:port]).to be <= 500
    end
  end

  describe '.prepare_configuration_file_content' do
    let(:conf) do
      {
        error_log_file: '/nginx/error.log',
        access_log_file: '/nginx/access.log',
        pid_file: '/nginx/nginx.pid',
        auth_file: '/nginx/file.auth',
        root_dir: '/cloudkeeper/images',
        image_file: 'image.ext',
        ip_address: '127.0.0.1',
        port: 12_345
      }
    end
    let(:configuration_file_content) { File.read(File.join(MOCK_DIR, 'nginx', 'configuration')) }

    it 'populates prepared NGINX configuration template' do
      expect(http_server.send(:prepare_configuration_file_content, conf)).to eq(configuration_file_content)
    end
  end

  describe 'prepare_configuration_file' do
    let(:conf) do
      {
        error_log_file: '/nginx/error.log',
        access_log_file: '/nginx/access.log',
        pid_file: '/nginx/nginx.pid',
        auth_file: '/nginx/file.auth',
        root_dir: '/cloudkeeper/images',
        image_file: 'image.ext',
        ip_address: '127.0.0.1',
        port: 12_345
      }
    end
    let(:auth_file) { Struct.new(:path).new '/nginx/file.auth' }
    let(:configuration_file) { File.join(MOCK_DIR, 'nginx', 'configuration') }

    before do
      http_server.instance_variable_set(:@auth_file, auth_file)
    end

    after do
      http_server.conf_file.unlink
    end

    it 'creates NGINX configuration file' do
      http_server.send(:prepare_configuration_file, conf)
      expect(configuration_file).to be_same_file_as(http_server.conf_file.path)
    end
  end

  describe 'write_configuration_file' do
    let(:configuration_file_content) { File.read(File.join(MOCK_DIR, 'nginx', 'configuration')) }

    after do
      http_server.conf_file.unlink
    end

    it 'writes NGINX configuration file' do
      http_server.send(:write_configuration_file, configuration_file_content)
      expect(configuration_file_content).to eq(File.read(http_server.conf_file.path))
    end
  end

  describe 'write_auth_file' do
    let(:username) { 'albus' }
    let(:password) { 'Rictusempra' }

    after do
      http_server.auth_file.unlink
    end

    it 'writes username and password into .htpasswd file' do
      http_server.send(:write_auth_file, username, password)
      passwd = WEBrick::HTTPAuth::Htpasswd.new(http_server.auth_file.path)
      expect(passwd.get_passwd(nil, username, true)).not_to be_nil
    end
  end

  describe 'prepare_credentials' do
    after do
      http_server.auth_file.unlink
    end

    it 'prepares .htpasswd file and returns used username and password' do
      auth = http_server.send(:prepare_credentials)
      passwd = WEBrick::HTTPAuth::Htpasswd.new(http_server.auth_file.path)
      expect(passwd.get_passwd(nil, auth[:username], true)).not_to be_nil
    end
  end

  describe 'start' do
    let(:image_file) { '/cloudkeeper/images/image.ext' }

    before do
      Cloudkeeper::Settings[:'nginx-binary'] = '/path/to/nginx'
      Cloudkeeper::Settings[:'nginx-error-log-file'] = '/nginx/error.log'
      Cloudkeeper::Settings[:'nginx-access-log-file'] = '/nginx/access.log'
      Cloudkeeper::Settings[:'nginx-pid-file'] = '/nginx/nginx.pid'
      Cloudkeeper::Settings[:'nginx-ip-address'] = '127.0.0.1'
      Cloudkeeper::Settings[:'nginx-min-port'] = 12_345
      Cloudkeeper::Settings[:'nginx-max-port'] = 12_345

      expect(Cloudkeeper::CommandExecutioner).to receive(:execute).with('/path/to/nginx', '-c', kind_of(String))
    end

    after do
      http_server.auth_file.unlink
      http_server.conf_file.unlink
    end

    it 'starts the NGINX server and returns access credentials' do
      http_server.start image_file

      expect(http_server.access_data).to include(:username)
      expect(http_server.access_data).to include(:password)
      expect(http_server.access_data).to include(:url)
    end
  end

  describe 'stop' do
    let(:auth_file) { Tempfile.new('cloudkeeper-nginx-spec') }
    let(:conf_file) { Tempfile.new('cloudkeeper-nginx-spec') }

    before do
      Cloudkeeper::Settings[:'nginx-binary'] = '/path/to/nginx'
      http_server.instance_variable_set(:@auth_file, auth_file)
      http_server.instance_variable_set(:@conf_file, conf_file)

      expect(Cloudkeeper::CommandExecutioner).to receive(:execute).with('/path/to/nginx', '-s', 'stop', '-c', kind_of(String))
      allow(auth_file).to receive(:unlink)
      allow(conf_file).to receive(:unlink)
    end

    it 'stops NGINX server and removes temporary files and access data' do
      http_server.stop

      expect(http_server.access_data).to be_empty

      expect(auth_file).to have_received(:unlink)
      expect(conf_file).to have_received(:unlink)
    end
  end

  describe 'fill_access_data' do
    let(:credentials) { { username: 'albus', password: 'Rictusempra' } }
    let(:conf) do
      {
        error_log_file: '/nginx/error.log',
        access_log_file: '/nginx/access.log',
        pid_file: '/nginx/nginx.pid',
        auth_file: '/nginx/file.auth',
        root_dir: '/cloudkeeper/images',
        image_file: 'image.ext',
        ip_address: '127.0.0.1',
        port: 12_345
      }
    end

    it 'fills access_data attribute' do
      http_server.send(:fill_access_data, credentials, conf)

      expect(http_server.access_data[:username]).to eq('albus')
      expect(http_server.access_data[:password]).to eq('Rictusempra')
      expect(http_server.access_data[:url]).to eq('http://127.0.0.1:12345/image.ext')
    end
  end
end
