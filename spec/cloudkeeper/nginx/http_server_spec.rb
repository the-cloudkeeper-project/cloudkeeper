require 'spec_helper'

describe Cloudkeeper::Nginx::HttpServer do
  subject(:http_server) { described_class.new }

  describe '.choose_password' do
    it 'each time returns randomly generated 50 characters long password' do
      pass1 = http_server.send(:choose_password)
      pass2 = http_server.send(:choose_password)
      pass3 = http_server.send(:choose_password)

      expect(pass1).not_to eq(pass2)
      expect(pass1).not_to eq(pass3)
      expect(pass2).not_to eq(pass3)

      expect(pass1.length).to be >= 45
      expect(pass2.length).to be >= 45
      expect(pass3.length).to be >= 45
    end
  end

  describe '.choose_name' do
    it 'each time returns different name' do
      name1 = http_server.send(:choose_name)
      name2 = http_server.send(:choose_name)
      name3 = http_server.send(:choose_name)

      expect(name1).not_to eq(name2)
      expect(name1).not_to eq(name3)
      expect(name2).not_to eq(name3)
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

      expect(port1).not_to eq(port2)
      expect(port1).not_to eq(port3)
      expect(port2).not_to eq(port3)

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
    let(:image_file) { '/cloudkeeper/images/image.ext' }
    let(:auth_file) { Struct.new(:path).new '/nginx/file.auth' }
    let(:configuration_file) { File.join(MOCK_DIR, 'nginx', 'configuration') }

    before do
      Cloudkeeper::Settings[:'nginx-error-log-file'] = '/nginx/error.log'
      Cloudkeeper::Settings[:'nginx-access-log-file'] = '/nginx/access.log'
      Cloudkeeper::Settings[:'nginx-pid-file'] = '/nginx/nginx.pid'
      Cloudkeeper::Settings[:'nginx-ip-address'] = '127.0.0.1'
      Cloudkeeper::Settings[:'nginx-min-port'] = 12_345
      Cloudkeeper::Settings[:'nginx-max-port'] = 12_345
      http_server.instance_variable_set(:@auth_file, auth_file)
    end

    after do
      http_server.conf_file.unlink
    end

    it 'creates NGINX configuration file' do
      http_server.send(:prepare_configuration_file, image_file)
      expect(configuration_file).to be_same_file_as(http_server.conf_file.path)
    end
  end

  describe 'write_auth_file' do
    let(:name) { 'albus' }
    let(:password) { 'Rictusempra' }
    let(:auth_file) { Tempfile.new('cloudkeeper-nginx-spec') }

    before do
      http_server.instance_variable_set(:@auth_file, auth_file)
    end

    after do
      auth_file.unlink
    end

    it 'writes name and password into .htpasswd file' do
      http_server.send(:write_auth_file, name, password)
      passwd = WEBrick::HTTPAuth::Htpasswd.new(auth_file.path)
      expect(passwd.get_passwd(nil, name, true)).not_to be_nil
    end
  end

  describe 'prepare_auth_file' do
    after do
      http_server.auth_file.unlink
    end

    it 'prepares .htpasswd file and returns used name and password' do
      auth = http_server.send(:prepare_auth_file)
      passwd = WEBrick::HTTPAuth::Htpasswd.new(http_server.auth_file.path)
      expect(passwd.get_passwd(nil, auth[:name], true)).not_to be_nil
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
      auth = http_server.start image_file

      expect(auth).to include(:name)
      expect(auth).to include(:password)
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
      expect(auth_file).to receive(:unlink)
      expect(conf_file).to receive(:unlink)
    end

    it 'stops NGINX server and removes temporary files' do
      http_server.stop
    end
  end
end
