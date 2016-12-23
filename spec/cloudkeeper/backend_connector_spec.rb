require 'spec_helper'

describe Cloudkeeper::BackendConnector do
  subject(:backend_connector) { described_class.new }
  let(:status_success) { Struct.new(:code).new :SUCCESS }
  let(:status_error) { Struct.new(:code, :message).new :ERROR, 'message' }

  before do
    Cloudkeeper::Settings[:'backend-endpoint'] = '127.0.0.1:50051'
  end

  describe '#new' do
    it 'returns instance of BackendConnector' do
      is_expected.to be_instance_of described_class
    end

    it 'initializes grpc client and nginx manager' do
      expect(backend_connector.grpc_client).to be_instance_of Cloudkeeper::Grpc::Communicator::Stub
      expect(backend_connector.nginx).to be_instance_of Cloudkeeper::Nginx::HttpServer
    end

    it 'initializes grpc client with correct backend address' do
      expect(Cloudkeeper::Grpc::Communicator::Stub).to receive(:new).with('127.0.0.1:50051', any_args)
      described_class.new
    end
  end

  describe '.pre_action' do
    context 'with successfull run' do
      before do
        expect(backend_connector.grpc_client).to receive(:pre_action) { status_success }
      end

      it "doesn't raise any errors" do
        expect { backend_connector.pre_action }.not_to raise_error
      end
    end

    context 'with an error' do
      before do
        expect(backend_connector.grpc_client).to receive(:pre_action) { status_error }
      end

      it 'raises BackendError exception' do
        expect { backend_connector.pre_action }.to raise_error(Cloudkeeper::Errors::BackendError)
      end
    end
  end

  describe '.post_action' do
    context 'with successfull run' do
      before do
        expect(backend_connector.grpc_client).to receive(:post_action) { status_success }
      end

      it "doesn't raise any errors" do
        expect { backend_connector.post_action }.not_to raise_error
      end
    end

    context 'with an error' do
      before do
        expect(backend_connector.grpc_client).to receive(:post_action) { status_error }
      end

      it 'raises BackendError exception' do
        expect { backend_connector.post_action }.to raise_error(Cloudkeeper::Errors::BackendError)
      end
    end
  end

  describe '.migrate' do
    context 'with successfull run' do
      before do
        expect(backend_connector.grpc_client).to receive(:migrate) { status_success }
      end

      it "doesn't raise any errors" do
        expect { backend_connector.migrate }.not_to raise_error
      end
    end

    context 'with an error' do
      before do
        expect(backend_connector.grpc_client).to receive(:migrate) { status_error }
      end

      it 'raises BackendError exception' do
        expect { backend_connector.migrate }.to raise_error(Cloudkeeper::Errors::BackendError)
      end
    end
  end

  describe '.remove_image_list' do
    let(:image_list_identifier) { 'id123456' }
    let(:image_list_identifier_proto) { instance_double(Cloudkeeper::Grpc::ImageListIdentifier) }

    before do
      expect(Cloudkeeper::Grpc::ImageListIdentifier).to receive(:new).with(image_list_identifier: image_list_identifier) \
        { image_list_identifier_proto }
    end

    context 'with successfull run' do
      before do
        expect(backend_connector.grpc_client).to receive(:remove_image_list).with(image_list_identifier_proto) { status_success }
      end

      it "doesn't raise any errors" do
        expect { backend_connector.remove_image_list(image_list_identifier) }.not_to raise_error
      end
    end

    context 'with an error' do
      before do
        expect(backend_connector.grpc_client).to receive(:remove_image_list).with(image_list_identifier_proto) { status_error }
      end

      it 'raises BackendError exception' do
        expect { backend_connector.remove_image_list(image_list_identifier) }.to raise_error(Cloudkeeper::Errors::BackendError)
      end
    end
  end

  describe '.image_lists' do
    let(:image_list_identifiers) { %w(id123 id456 id789) }
    let(:image_list_identifiers_proto) do
      [
        Struct.new(:image_list_identifier).new('id123'),
        Struct.new(:image_list_identifier).new('id456'),
        Struct.new(:image_list_identifier).new('id789')
      ]
    end

    before do
      expect(backend_connector.grpc_client).to receive(:image_lists) { image_list_identifiers_proto }
    end

    it 'returns a list of image list identifiers' do
      expect(backend_connector.image_lists).to eq(image_list_identifiers)
    end
  end

  describe '.check_status' do
    context 'with status success' do
      it "won't raise any exceptions" do
        expect { backend_connector.send(:check_status, status_success) }.not_to raise_error
      end
    end

    context 'with other status then success' do
      it 'raises BackendError exception' do
        expect { backend_connector.send(:check_status, status_error) }.to raise_error(Cloudkeeper::Errors::BackendError)
      end
    end
  end

  describe '.acceptable_image_file' do
    let(:selected_image_file) { Struct.new(:format).new(:qcow2) }
    let(:image_files) do
      [
        selected_image_file,
        Struct.new(:format).new(:raw)
      ]
    end
    let(:image) { Cloudkeeper::Entities::Image.new 'http://some.uri.net', '1a2b3c4d', 10, image_files }

    before do
      Cloudkeeper::Settings[:'output-formats'] = %w(qcow2 vmdk)
    end

    it 'returns image file that suffice format requirements' do
      expect(backend_connector.send(:acceptable_image_file, image)).to eq(selected_image_file)
    end

    context 'with no acceptable image file available' do
      before do
        Cloudkeeper::Settings[:'output-formats'] = ['nonexisting_format']
      end

      it 'raises NoRequiredFormatAvailableError execption' do
        expect { backend_connector.send(:acceptable_image_file, image) }.to \
          raise_error(Cloudkeeper::Errors::ImageFormat::NoRequiredFormatAvailableError)
      end
    end
  end

  describe '.set_remote_data' do
    let(:image_proto) { Struct.new(:mode, :location, :username, :password).new }
    let(:access_data) { { url: 'http://some.url.net', username: 'username', password: 'password' } }

    it 'populates image proto instance with data for remote access' do
      backend_connector.send(:set_remote_data, image_proto, access_data)

      expect(image_proto.mode).to eq(:REMOTE)
      expect(image_proto.location).to eq('http://some.url.net')
      expect(image_proto.username).to eq('username')
      expect(image_proto.password).to eq('password')
    end
  end

  describe '.convert_image' do
    let(:selected_image_file) { Struct.new(:format, :checksum, :file).new(:qcow2, '1a2b3c4d5e', '/some/image/file.ext') }
    let(:image_files) do
      [
        selected_image_file,
        Struct.new(:format).new(:raw)
      ]
    end
    let(:image) { Cloudkeeper::Entities::Image.new 'http://some.uri.net', '1a2b3c4d', 10, image_files }

    before do
      Cloudkeeper::Settings[:'output-formats'] = %w(qcow2 vmdk)
    end

    it 'converts image entity into image proto entity' do
      image_proto = backend_connector.send(:convert_image, image)

      expect(image_proto.mode).to eq(:LOCAL)
      expect(image_proto.location).to eq('/some/image/file.ext')
      expect(image_proto.checksum).to eq('1a2b3c4d5e')
      expect(image_proto.size).to eq(10)
      expect(image_proto.uri).to eq('http://some.uri.net')
    end
  end

  describe '.convert_appliance' do
    let(:date) { DateTime.now }
    let(:image_proto) { Cloudkeeper::Grpc::Image.new }
    let(:appliance) do
      Cloudkeeper::Entities::Appliance.new 'id12345', 'http://mp.uri.net', 'vo', date, 'ilid12345', 'title',
                                           'description', 'group', 2048, 6, 'v01', 'x86_64', 'Linux', nil, 'key' => 'value'
    end

    it 'converts appliance entity into appliance proto entity' do
      appliance_proto = backend_connector.send(:convert_appliance, appliance, image_proto)

      expect(appliance_proto.identifier).to eq('id12345')
      expect(appliance_proto.description).to eq('description')
      expect(appliance_proto.mpuri).to eq('http://mp.uri.net')
      expect(appliance_proto.title).to eq('title')
      expect(appliance_proto.group).to eq('group')
      expect(appliance_proto.ram).to eq(2048)
      expect(appliance_proto.core).to eq(6)
      expect(appliance_proto.version).to eq('v01')
      expect(appliance_proto.architecture).to eq('x86_64')
      expect(appliance_proto.operating_system).to eq('Linux')
      expect(appliance_proto.vo).to eq('vo')
      expect(appliance_proto.expiration_date).to eq(date.to_i)
      expect(appliance_proto.image_list_identifier).to eq('ilid12345')
      expect(appliance_proto.image).to eq(image_proto)
      expect(appliance_proto.attributes).to eq('key' => 'value')
    end
  end

  describe '.convert_image_proto' do
    let(:image_proto) { Struct.new(:uri, :checksum, :size).new 'http://some.uri.net', '1a2b3c4d5e', 15 }

    it 'convetrs image proto instance to image entity instance' do
      image = backend_connector.send(:convert_image_proto, image_proto)

      expect(image.uri).to eq('http://some.uri.net')
      expect(image.checksum).to eq('1a2b3c4d5e')
      expect(image.size).to eq(15)
    end

    context 'with nil input' do
      it 'returns nil' do
        expect(backend_connector.send(:convert_image_proto, nil)).to be_nil
      end
    end
  end

  describe '.convert_appliance_proto' do
    let(:date) { DateTime.now }
    let(:image) { instance_double(Cloudkeeper::Entities::Image) }
    let(:appliance_proto) do
      Struct.new(:identifier, :description, :mpuri, :title, :group,
                 :ram, :core, :version, :architecture, :operating_system,
                 :image, :attributes, :vo, :expiration_date,
                 :image_list_identifier).new 'id12345', 'description', 'http://mp.uri.net', 'title', 'group', 2048, 6, 'v01',
                                             'x86_64', 'Linux', image, { 'key' => 'value' }, 'vo', date.to_i, 'ilid12345'
    end

    it 'converts appliance proto inatance to appliance entity instance' do
      appliance = backend_connector.send(:convert_appliance_proto, appliance_proto, image)

      expect(appliance.identifier).to eq('id12345')
      expect(appliance.description).to eq('description')
      expect(appliance.mpuri).to eq('http://mp.uri.net')
      expect(appliance.title).to eq('title')
      expect(appliance.group).to eq('group')
      expect(appliance.ram).to eq(2048)
      expect(appliance.core).to eq(6)
      expect(appliance.version).to eq('v01')
      expect(appliance.architecture).to eq('x86_64')
      expect(appliance.operating_system).to eq('Linux')
      expect(appliance.vo).to eq('vo')
      expect(appliance.expiration_date.to_date).to eq(date.to_date)
      expect(appliance.image_list_identifier).to eq('ilid12345')
      expect(appliance.image).to eq(image)
      expect(appliance.attributes).to eq('key' => 'value')
    end
  end

  describe '.manage_appliance' do
    let(:date) { DateTime.now }
    let(:appliance) do
      Cloudkeeper::Entities::Appliance.new 'id12345', 'http://mp.uri.net', 'vo', date, 'ilid12345', 'title',
                                           'description', 'group', 2048, 6, 'v01', 'x86_64', 'Linux', nil, 'key' => 'value'
    end
    let(:appliance_proto) do
      Struct.new(:identifier, :description, :mpuri, :title, :group,
                 :ram, :core, :version, :architecture, :operating_system,
                 :image, :attributes, :vo, :expiration_date,
                 :image_list_identifier).new 'id12345', 'description', 'http://mp.uri.net', 'title', 'group', 2048, 6, 'v01',
                                             'x86_64', 'Linux', nil, { 'key' => 'value' }, 'vo', date.to_i, 'ilid12345'
    end
    let(:call) { :remove_appliance }

    before do
      Cloudkeeper::Settings[:'output-formats'] = %w(qcow2 vmdk)
    end

    context 'in local mode' do
      before do
        Cloudkeeper::Settings[:'remote-mode'] = false
        expect(backend_connector.nginx).not_to receive(:start)
        expect(backend_connector.nginx).not_to receive(:stop)
      end

      context 'with successfull run' do
        before do
          expect(backend_connector.grpc_client).to receive(call) { status_success }
        end

        it 'converts appliance and calls specified gRPC method' do
          expect { backend_connector.send(:manage_appliance, appliance, call) }.not_to raise_error
        end
      end

      context 'with an error' do
        before do
          expect(backend_connector.grpc_client).to receive(call) { status_error }
        end

        it 'raises BackendError exception' do
          expect { backend_connector.send(:manage_appliance, appliance, call) }.to raise_error(Cloudkeeper::Errors::BackendError)
        end
      end
    end

    context 'in remote mode with image' do
      let(:image_files) do
        [
          Struct.new(:format, :checksum, :file).new(:qcow2, '1a2b3c4d5e', '/some/image/file.ext'),
          Struct.new(:format).new(:raw)
        ]
      end
      let(:image) { Cloudkeeper::Entities::Image.new 'http://some.uri.net', '1a2b3c4d', 10, image_files }
      let(:image_proto) { Struct.new(:uri, :checksum, :size, :location, :mode, :username, :password).new }

      before do
        Cloudkeeper::Settings[:'remote-mode'] = true
        appliance.image = image
        expect(backend_connector.nginx).to receive(:start)
        expect(backend_connector.nginx).to receive(:stop)
        allow(backend_connector.nginx).to receive(:access_data) { { url: '', username: '', password: '' } }
      end

      context 'with successfull run' do
        before do
          expect(backend_connector.grpc_client).to receive(call) { status_success }
        end

        it 'converts appliance, starts HTTP server calls specified gRPC method and stops HTTP server' do
          expect { backend_connector.send(:manage_appliance, appliance, call) }.not_to raise_error
        end
      end

      context 'with an error' do
        before do
          expect(backend_connector.grpc_client).to receive(call) { status_error }
        end

        it 'raises BackendError exception' do
          expect { backend_connector.send(:manage_appliance, appliance, call) }.to raise_error(Cloudkeeper::Errors::BackendError)
        end
      end
    end

    context 'in remote mode without image' do
      before do
        Cloudkeeper::Settings[:'remote-mode'] = true
        expect(backend_connector.nginx).not_to receive(:start)
        expect(backend_connector.nginx).not_to receive(:stop)
        allow(backend_connector.nginx).to receive(:access_data) { { url: '', username: '', password: '' } }
      end

      context 'with successfull run' do
        before do
          expect(backend_connector.grpc_client).to receive(call) { status_success }
        end

        it 'converts appliance and calls specified gRPC method' do
          expect { backend_connector.send(:manage_appliance, appliance, call) }.not_to raise_error
        end
      end

      context 'with an error' do
        before do
          expect(backend_connector.grpc_client).to receive(call) { status_error }
        end

        it 'raises BackendError exception' do
          expect { backend_connector.send(:manage_appliance, appliance, call) }.to raise_error(Cloudkeeper::Errors::BackendError)
        end
      end
    end
  end

  describe '.add_appliance' do
    let(:date) { DateTime.now }
    let(:appliance) do
      Cloudkeeper::Entities::Appliance.new 'id12345', 'http://mp.uri.net', 'vo', date, 'ilid12345', 'title',
                                           'description', 'group', 2048, 6, 'v01', 'x86_64', 'Linux', nil, 'key' => 'value'
    end

    before do
      expect(backend_connector).to receive(:manage_appliance).with(appliance, :add_appliance)
    end

    it 'calls remote method to add appliance' do
      backend_connector.add_appliance(appliance)
    end
  end

  describe '.update_appliance' do
    let(:date) { DateTime.now }
    let(:appliance) do
      Cloudkeeper::Entities::Appliance.new 'id12345', 'http://mp.uri.net', 'vo', date, 'ilid12345', 'title',
                                           'description', 'group', 2048, 6, 'v01', 'x86_64', 'Linux', nil, 'key' => 'value'
    end

    before do
      expect(backend_connector).to receive(:manage_appliance).with(appliance, :update_appliance)
    end

    it 'calls remote method to add appliance' do
      backend_connector.update_appliance(appliance)
    end
  end

  describe '.remove_appliance' do
    let(:date) { DateTime.now }
    let(:appliance) do
      Cloudkeeper::Entities::Appliance.new 'id12345', 'http://mp.uri.net', 'vo', date, 'ilid12345', 'title',
                                           'description', 'group', 2048, 6, 'v01', 'x86_64', 'Linux', nil, 'key' => 'value'
    end

    before do
      expect(backend_connector).to receive(:manage_appliance).with(appliance, :remove_appliance)
    end

    it 'calls remote method to add appliance' do
      backend_connector.remove_appliance(appliance)
    end
  end

  describe '.appliances' do
    let(:date) { DateTime.now }
    let(:image_list_identifier) { 'id12345' }
    let(:appliances_proto) do
      [
        Struct.new(:identifier, :description, :mpuri, :title, :group,
                   :ram, :core, :version, :architecture, :operating_system,
                   :image, :attributes, :vo, :expiration_date,
                   :image_list_identifier).new('id123', 'description', 'http://mp.uri.net', 'title1', 'group', 2048, 6, 'v01',
                                               'x86_64', 'Linux', nil, { 'key' => 'value' }, 'vo', date.to_i, 'id12345'),
        Struct.new(:identifier, :description, :mpuri, :title, :group,
                   :ram, :core, :version, :architecture, :operating_system,
                   :image, :attributes, :vo, :expiration_date,
                   :image_list_identifier).new('id456', 'description', 'http://mp.uri.net', 'title2', 'group', 2048, 6, 'v01',
                                               'x86_64', 'Linux', nil, { 'key' => 'value' }, 'vo', date.to_i, 'id12345'),
        Struct.new(:identifier, :description, :mpuri, :title, :group,
                   :ram, :core, :version, :architecture, :operating_system,
                   :image, :attributes, :vo, :expiration_date,
                   :image_list_identifier).new('id789', 'description', 'http://mp.uri.net', 'title3', 'group', 2048, 6, 'v01',
                                               'x86_64', 'Linux', nil, { 'key' => 'value' }, 'vo', date.to_i, 'id12345')
      ]
    end

    before do
      expect(backend_connector.grpc_client).to receive(:appliances) { appliances_proto }
    end

    it 'returns list of appliances for specified image list identifier' do
      appliances = backend_connector.appliances(image_list_identifier)

      appliance = appliances[0]
      expect(appliance.identifier).to eq('id123')
      expect(appliance.description).to eq('description')
      expect(appliance.mpuri).to eq('http://mp.uri.net')
      expect(appliance.title).to eq('title1')
      expect(appliance.group).to eq('group')
      expect(appliance.ram).to eq(2048)
      expect(appliance.core).to eq(6)
      expect(appliance.version).to eq('v01')
      expect(appliance.architecture).to eq('x86_64')
      expect(appliance.operating_system).to eq('Linux')
      expect(appliance.attributes).to eq('key' => 'value')
      expect(appliance.vo).to eq('vo')
      expect(appliance.expiration_date.to_date).to eq(date.to_date)
      expect(appliance.image_list_identifier).to eq('id12345')
      expect(appliance.image).to eq(nil)

      appliance = appliances[1]
      expect(appliance.identifier).to eq('id456')
      expect(appliance.description).to eq('description')
      expect(appliance.mpuri).to eq('http://mp.uri.net')
      expect(appliance.title).to eq('title2')
      expect(appliance.group).to eq('group')
      expect(appliance.ram).to eq(2048)
      expect(appliance.core).to eq(6)
      expect(appliance.version).to eq('v01')
      expect(appliance.architecture).to eq('x86_64')
      expect(appliance.operating_system).to eq('Linux')
      expect(appliance.attributes).to eq('key' => 'value')
      expect(appliance.vo).to eq('vo')
      expect(appliance.expiration_date.to_date).to eq(date.to_date)
      expect(appliance.image_list_identifier).to eq('id12345')
      expect(appliance.image).to eq(nil)

      appliance = appliances[2]
      expect(appliance.identifier).to eq('id789')
      expect(appliance.description).to eq('description')
      expect(appliance.mpuri).to eq('http://mp.uri.net')
      expect(appliance.title).to eq('title3')
      expect(appliance.group).to eq('group')
      expect(appliance.ram).to eq(2048)
      expect(appliance.core).to eq(6)
      expect(appliance.version).to eq('v01')
      expect(appliance.architecture).to eq('x86_64')
      expect(appliance.operating_system).to eq('Linux')
      expect(appliance.attributes).to eq('key' => 'value')
      expect(appliance.vo).to eq('vo')
      expect(appliance.expiration_date.to_date).to eq(date.to_date)
      expect(appliance.image_list_identifier).to eq('id12345')
      expect(appliance.image).to eq(nil)
    end
  end
end
