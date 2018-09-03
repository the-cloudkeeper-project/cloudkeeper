require 'spec_helper'

describe Cloudkeeper::BackendConnector do
  subject(:backend_connector) { described_class.new }

  let(:empty) { Google::Protobuf::Empty.new }

  before do
    Cloudkeeper::Settings[:'backend-endpoint'] = '127.0.0.1:50051'
    Cloudkeeper::Settings[:authentication] = false
  end

  describe '#new' do
    it 'returns instance of BackendConnector' do
      expect(backend_connector).to be_instance_of described_class
    end

    it 'initializes grpc client and nginx manager' do
      expect(backend_connector.grpc_client).to be_instance_of CloudkeeperGrpc::Communicator::Stub
      expect(backend_connector.nginx).to be_instance_of Cloudkeeper::Nginx::HttpServer
    end

    it 'initializes grpc client with correct backend address' do
      allow(CloudkeeperGrpc::Communicator::Stub).to receive(:new).with('127.0.0.1:50051', any_args)
      described_class.new
      expect(CloudkeeperGrpc::Communicator::Stub).to have_received(:new).with('127.0.0.1:50051', any_args)
    end
  end

  describe '.pre_action' do
    before do
      allow(backend_connector.grpc_client).to receive(:pre_action) { empty }
    end

    context 'with successfull run' do
      it "doesn't raise any errors" do
        expect { backend_connector.pre_action }.not_to raise_error
      end

      it 'calls method on gRPC client instance' do
        backend_connector.pre_action
        expect(backend_connector.grpc_client).to have_received(:pre_action) { empty }
      end
    end

    context 'with an error' do
      before do
        allow(backend_connector.grpc_client).to receive(:pre_action).and_raise(GRPC::BadStatus.new(42, 'pre_action error'))
      end

      it 'raises BackendError exception' do
        expect { backend_connector.pre_action }.to raise_error(Cloudkeeper::Errors::BackendError)
      end
    end
  end

  describe '.post_action' do
    before do
      allow(backend_connector.grpc_client).to receive(:post_action) { empty }
    end

    context 'with successfull run' do
      it "doesn't raise any errors" do
        expect { backend_connector.post_action }.not_to raise_error
      end

      it 'calls method on gRPC client instance' do
        backend_connector.post_action
        expect(backend_connector.grpc_client).to have_received(:post_action) { empty }
      end
    end

    context 'with an error' do
      before do
        allow(backend_connector.logger).to receive(:error)
        allow(backend_connector.grpc_client).to receive(:post_action).and_raise(GRPC::BadStatus.new(42, 'post_action error'))
      end

      it 'logs an error' do
        backend_connector.post_action
        expect(backend_connector.logger).to have_received(:error)
      end
    end
  end

  describe '.remove_image_list' do
    let(:image_list_identifier) { 'id123456' }
    let(:image_list_identifier_proto) { instance_double(CloudkeeperGrpc::ImageListIdentifier) }

    before do
      allow(CloudkeeperGrpc::ImageListIdentifier).to receive(:new).with(image_list_identifier: image_list_identifier) \
        { image_list_identifier_proto }
      allow(backend_connector.grpc_client).to receive(:remove_image_list).with(image_list_identifier_proto) \
        { empty }
    end

    context 'with successfull run' do
      it "doesn't raise any errors" do
        expect { backend_connector.remove_image_list(image_list_identifier) }.not_to raise_error
      end

      it 'calls method on gRPC client instance' do
        backend_connector.remove_image_list(image_list_identifier)
        expect(backend_connector.grpc_client).to have_received(:remove_image_list).with(image_list_identifier_proto) { empty }
      end
    end

    context 'with an error' do
      before do
        allow(backend_connector.logger).to receive(:error)
        allow(backend_connector.grpc_client).to \
          receive(:remove_image_list).and_raise(GRPC::BadStatus.new(42, 'remove_image_list error'))
      end

      it 'logs an error' do
        backend_connector.remove_image_list(image_list_identifier)
        expect(backend_connector.logger).to have_received(:error)
      end
    end
  end

  describe '.image_lists' do
    let(:image_list_identifiers) { %w[id123 id456 id789] }
    let(:image_list_identifiers_proto) do
      [
        Struct.new(:image_list_identifier).new('id123'),
        Struct.new(:image_list_identifier).new('id456'),
        Struct.new(:image_list_identifier).new('id789')
      ]
    end

    context 'with successfull run' do
      before do
        allow(backend_connector.grpc_client).to receive(:image_lists) { image_list_identifiers_proto }
      end

      it 'returns a list of image list identifiers' do
        expect(backend_connector.image_lists).to eq(image_list_identifiers)
      end

      it 'calls method on gRPC client instance' do
        backend_connector.image_lists
        expect(backend_connector.grpc_client).to have_received(:image_lists) { image_list_identifiers_proto }
      end
    end

    context 'with an error' do
      before do
        allow(backend_connector.grpc_client).to receive(:image_lists).and_raise(GRPC::BadStatus.new(42, 'image_lists error'))
      end

      it 'raises BackendError exception' do
        expect { backend_connector.image_lists }.to raise_error(Cloudkeeper::Errors::BackendError)
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
    let(:image) { Cloudkeeper::Entities::Image.new 'http://some.uri.net', '1a2b3c4d', 10, 'd4c3b2a1', image_files }

    before do
      Cloudkeeper::Settings[:formats] = %w[qcow2 vmdk]
    end

    it 'returns image file that suffice format requirements' do
      expect(backend_connector.send(:acceptable_image_file, image)).to eq(selected_image_file)
    end

    context 'with no acceptable image file available' do
      before do
        Cloudkeeper::Settings[:formats] = ['nonexisting_format']
      end

      it 'raises NoRequiredFormatAvailableError execption' do
        expect { backend_connector.send(:acceptable_image_file, image) }.to \
          raise_error(Cloudkeeper::Errors::Image::Format::NoRequiredFormatAvailableError)
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
    let(:selected_image_file) { Struct.new(:format, :checksum, :file, :size).new(:qcow2, '1a2b3c4d5e', '/some/image/file.ext', 154) }
    let(:image_files) do
      [
        selected_image_file,
        Struct.new(:format).new(:raw)
      ]
    end
    let(:image) { Cloudkeeper::Entities::Image.new 'http://some.uri.net', '1a2b3c4d', 10, 'd4c3b2a1', image_files }

    before do
      Cloudkeeper::Settings[:formats] = %w[qcow2 vmdk]
    end

    it 'converts image entity into image proto entity' do
      image_proto = backend_connector.send(:convert_image, image)

      expect(image_proto.mode).to eq(:LOCAL)
      expect(image_proto.location).to eq('/some/image/file.ext')
      expect(image_proto.checksum).to eq('1a2b3c4d5e')
      expect(image_proto.size).to eq(154)
      expect(image_proto.uri).to eq('http://some.uri.net')
      expect(image_proto.digest).to eq('d4c3b2a1')
    end
  end

  describe '.convert_appliance' do
    let(:date) { Time.now }
    let(:image_proto) { CloudkeeperGrpc::Image.new }
    let(:appliance) do
      Cloudkeeper::Entities::Appliance.new 'id12345', 'http://mp.uri.net', 'vo', date, 'ilid12345', 'title', 'description',
                                           'group', 2048, 6, 'v01', 'x86_64', 'http://basemp.uri.net', '64156', '6dfe12a',
                                           'Linux', image_proto
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
      expect(appliance_proto.base_mpuri).to eq('http://basemp.uri.net')
      expect(appliance_proto.appid).to eq('64156')
      expect(appliance_proto.digest).to eq('6dfe12a')
    end
  end

  describe '.convert_image_proto' do
    let(:image_proto) { Struct.new(:uri, :checksum, :size, :digest).new 'http://some.uri.net', '1a2b3c4d5e', 15, '6dfe12a' }

    it 'convetrs image proto instance to image entity instance' do
      image = backend_connector.send(:convert_image_proto, image_proto)

      expect(image.uri).to eq('http://some.uri.net')
      expect(image.checksum).to eq('1a2b3c4d5e')
      expect(image.size).to eq(15)
      expect(image.digest).to eq('6dfe12a')
    end
  end

  describe '.convert_appliance_proto' do
    let(:date) { Time.now }
    let(:image) { instance_double(Cloudkeeper::Entities::Image) }
    let(:appliance_proto) do
      Struct.new(:identifier, :description, :mpuri, :title, :group,
                 :ram, :core, :version, :architecture, :operating_system,
                 :image, :vo, :expiration_date, :base_mpuri, :appid, :digest,
                 :image_list_identifier).new 'id12345', 'description', 'http://mp.uri.net', 'title', 'group', 2048, 6, 'v01',
                                             'x86_64', 'Linux', image, 'vo', date.to_i, 'http://basemp.uri.net', '564184',
                                             '6dfe12a', 'ilid12345'
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
      expect(appliance.base_mpuri).to eq('http://basemp.uri.net')
      expect(appliance.appid).to eq('564184')
      expect(appliance.digest).to eq('6dfe12a')
    end
  end

  describe '.manage_appliance' do
    let(:date) { Time.now }
    let(:selected_image_file) { Struct.new(:format, :checksum, :file, :size).new(:qcow2, '1a2b3c4d5e', '/some/image/file.ext', 154) }
    let(:image_files) do
      [
        selected_image_file,
        Struct.new(:format).new(:raw)
      ]
    end
    let(:image) { Cloudkeeper::Entities::Image.new 'http://some.uri.net', '1a2b3c4d', 10, 'd4c3b2a1', image_files }
    let(:appliance) do
      Cloudkeeper::Entities::Appliance.new 'id12345', 'http://mp.uri.net', 'vo', date, 'ilid12345', 'title',
                                           'description', 'group', 2048, 6, 'v01', 'x86_64', 'http://basemp.uri.net', '64156',
                                           '6dfe12a', 'Linux', image
    end
    let(:image_proto) { CloudkeeperGrpc::Image.new }
    let(:appliance_proto) do
      Struct.new(:identifier, :description, :mpuri, :title, :group,
                 :ram, :core, :version, :architecture, :operating_system,
                 :image, :vo, :expiration_date, :base_mpuri, :appid, :digest,
                 :image_list_identifier).new 'id12345', 'description', 'http://mp.uri.net', 'title', 'group', 2048, 6, 'v01',
                                             'x86_64', 'Linux', image_proto, 'vo', date.to_i, 'http://basemp.uri.net', '564184',
                                             '6dfe12a', 'ilid12345'
    end
    let(:call) { :add_appliance }

    before do
      Cloudkeeper::Settings[:formats] = %w[qcow2 vmdk]
    end

    context 'when in local mode' do
      before do
        Cloudkeeper::Settings[:'remote-mode'] = false
        allow(backend_connector.nginx).to receive(:start)
        allow(backend_connector.nginx).to receive(:stop)
        allow(backend_connector.grpc_client).to receive(call) { empty }
      end

      context 'with successfull run' do
        it 'converts appliance' do
          expect { backend_connector.send(:manage_appliance, appliance, call) }.not_to raise_error
        end

        it 'calls method on gRPC client instance' do
          backend_connector.send(:manage_appliance, appliance, call)
          expect(backend_connector.grpc_client).to have_received(call) { empty }
        end

        it 'doesn\'t starts nginx server' do
          backend_connector.send(:manage_appliance, appliance, call)
          expect(backend_connector.nginx).not_to have_received(:start)
        end

        it 'doesn\'t stops nginx server' do
          backend_connector.send(:manage_appliance, appliance, call)
          expect(backend_connector.nginx).not_to have_received(:stop)
        end
      end

      context 'with an error in backend communication' do
        before do
          allow(backend_connector.grpc_client).to receive(call).and_raise(GRPC::BadStatus.new(42, 'manage_appliance_with_image error'))
          allow(backend_connector.logger).to receive(:error)
        end

        it 'logs an error' do
          backend_connector.send(:manage_appliance, appliance, call)
          expect(backend_connector.logger).to have_received(:error)
        end
      end
    end

    context 'when in remote mode' do
      let(:image_files) do
        [
          Struct.new(:format, :checksum, :file).new(:qcow2, '1a2b3c4d5e', '/some/image/file.ext'),
          Struct.new(:format).new(:raw)
        ]
      end
      let(:image) { Cloudkeeper::Entities::Image.new 'http://some.uri.net', '1a2b3c4d', 10, '123abcd', image_files }
      let(:image_proto) { Struct.new(:uri, :checksum, :size, :location, :mode, :username, :password).new }

      before do
        Cloudkeeper::Settings[:'remote-mode'] = true
        appliance.image = image
        allow(backend_connector.nginx).to receive(:start)
        allow(backend_connector.nginx).to receive(:stop)
        allow(backend_connector.nginx).to receive(:access_data).and_return(url: '', username: '', password: '')
      end

      context 'with successfull run' do
        before do
          allow(backend_connector.grpc_client).to receive(call) { empty }
        end

        it 'converts appliance' do
          expect { backend_connector.send(:manage_appliance, appliance, call) }.not_to raise_error
        end

        it 'calls method on gRPC client instance' do
          backend_connector.send(:manage_appliance, appliance, call)
          expect(backend_connector.grpc_client).to have_received(call) { empty }
        end

        it 'starts nginx server' do
          backend_connector.send(:manage_appliance, appliance, call)
          expect(backend_connector.nginx).to have_received(:start)
        end

        it 'stops nginx server' do
          backend_connector.send(:manage_appliance, appliance, call)
          expect(backend_connector.nginx).to have_received(:stop)
        end
      end

      context 'with an error in backend communication' do
        before do
          allow(backend_connector.grpc_client).to receive(call).and_raise(GRPC::BadStatus.new(42, 'manage_appliance error'))
          allow(backend_connector.logger).to receive(:error)
        end

        it 'logs an error' do
          backend_connector.send(:manage_appliance, appliance, call)
          expect(backend_connector.logger).to have_received(:error)
        end

        it 'calls method on gRPC client instance' do
          backend_connector.send(:manage_appliance, appliance, call)
          expect(backend_connector.grpc_client).to have_received(call) { empty }
        end
      end

      context 'without acceptable image format' do
        before do
          Cloudkeeper::Settings[:formats] = %w[ova]
        end

        it 'raises NoRequiredFormatAvailableError exception' do
          expect { backend_connector.send(:manage_appliance, appliance, call) }.to \
            raise_error(Cloudkeeper::Errors::Appliance::PropagationError)
        end
      end

      context 'with an error from NGINX server' do
        before do
          allow(backend_connector.nginx).to receive(:start).and_raise(Cloudkeeper::Errors::NginxError)
        end

        it 'raises PropagationError exception' do
          expect { backend_connector.send(:manage_appliance, appliance, call) }.to \
            raise_error(Cloudkeeper::Errors::Appliance::PropagationError)
        end
      end
    end
  end

  describe '.add_appliance' do
    let(:date) { Time.now }
    let(:image_files) do
      [
        Struct.new(:format, :checksum, :file).new(:qcow2, '1a2b3c4d5e', '/some/image/file.ext'),
        Struct.new(:format).new(:raw)
      ]
    end
    let(:image) { Cloudkeeper::Entities::Image.new 'http://some.uri.net', '1a2b3c4d', 10, '123abcd', image_files }
    let(:appliance) do
      Cloudkeeper::Entities::Appliance.new 'id12345', 'http://mp.uri.net', 'vo', date, 'ilid12345', 'title', 'description',
                                           'group', 2048, 6, 'v01', 'x86_64', 'http://basemp.uri.net', '64156', '6dfe12a',
                                           'Linux', image
    end

    before do
      allow(backend_connector).to receive(:manage_appliance).with(appliance, :add_appliance)
    end

    it 'calls remote method to add appliance' do
      backend_connector.add_appliance(appliance)

      expect(backend_connector).to have_received(:manage_appliance).with(appliance, :add_appliance)
    end
  end

  describe '.update_appliance' do
    let(:date) { Time.now }
    let(:image_files) do
      [
        Struct.new(:format, :checksum, :file).new(:qcow2, '1a2b3c4d5e', '/some/image/file.ext'),
        Struct.new(:format).new(:raw)
      ]
    end
    let(:image) { Cloudkeeper::Entities::Image.new 'http://some.uri.net', '1a2b3c4d', 10, '123abcd', image_files }
    let(:appliance) do
      Cloudkeeper::Entities::Appliance.new 'id12345', 'http://mp.uri.net', 'vo', date, 'ilid12345', 'title', 'description',
                                           'group', 2048, 6, 'v01', 'x86_64', 'http://basemp.uri.net', '64156', '6dfe12a',
                                           'Linux', image
    end

    before do
      allow(backend_connector).to receive(:manage_appliance).with(appliance, :update_appliance)
    end

    it 'calls remote method to add appliance' do
      backend_connector.update_appliance(appliance)

      expect(backend_connector).to have_received(:manage_appliance).with(appliance, :update_appliance)
    end
  end

  describe '.update_appliance_metadata' do
    let(:date) { Time.now }
    let(:image_files) do
      [
        Struct.new(:format, :checksum, :file).new(:qcow2, '1a2b3c4d5e', '/some/image/file.ext'),
        Struct.new(:format).new(:raw)
      ]
    end
    let(:image) { Cloudkeeper::Entities::Image.new 'http://some.uri.net', '1a2b3c4d', 10, '123abcd', image_files }
    let(:appliance) do
      Cloudkeeper::Entities::Appliance.new 'id12345', 'http://mp.uri.net', 'vo', date, 'ilid12345', 'title', 'description',
                                           'group', 2048, 6, 'v01', 'x86_64', 'http://basemp.uri.net', '64156', '6dfe12a',
                                           'Linux', image
    end

    before do
      allow(backend_connector).to receive(:manage_appliance).with(appliance, :update_appliance_metadata)
    end

    it 'calls remote method to add appliance' do
      backend_connector.update_appliance_metadata(appliance)

      expect(backend_connector).to have_received(:manage_appliance).with(appliance, :update_appliance_metadata)
    end
  end

  describe '.remove_appliance' do
    let(:date) { Time.now }
    let(:image_files) do
      [
        Struct.new(:format, :checksum, :file).new(:qcow2, '1a2b3c4d5e', '/some/image/file.ext'),
        Struct.new(:format).new(:raw)
      ]
    end
    let(:image) { Cloudkeeper::Entities::Image.new 'http://some.uri.net', '1a2b3c4d', 10, '123abcd', image_files }
    let(:appliance) do
      Cloudkeeper::Entities::Appliance.new 'id12345', 'http://mp.uri.net', 'vo', date, 'ilid12345', 'title', 'description',
                                           'group', 2048, 6, 'v01', 'x86_64', 'http://basemp.uri.net', '64156', '6dfe12a',
                                           'Linux', image
    end

    before do
      allow(backend_connector).to receive(:manage_appliance).with(appliance, :remove_appliance)
    end

    it 'calls remote method to add appliance' do
      backend_connector.remove_appliance(appliance)

      expect(backend_connector).to have_received(:manage_appliance).with(appliance, :remove_appliance)
    end
  end

  describe '.appliances' do
    let(:date) { Time.now }
    let(:image_list_identifier) { 'id12345' }
    let(:image_proto) { Struct.new(:uri, :checksum, :digest).new('http://some.uri', '123456789abcdef', 'abcde123') }
    let(:appliances_proto) do
      [
        Struct.new(:identifier, :description, :mpuri, :title, :group,
                   :ram, :core, :version, :architecture, :operating_system,
                   :image, :vo, :expiration_date, :base_mpuri, :appid, :digest,
                   :image_list_identifier).new('id123', 'description', 'http://mp.uri.net', 'title1', 'group', 2048, 6, 'v01',
                                               'x86_64', 'Linux', image_proto, 'vo', date.to_i, 'http://basemp.uri.net', '564184',
                                               '6dfe12a', 'id12345'),
        Struct.new(:identifier, :description, :mpuri, :title, :group,
                   :ram, :core, :version, :architecture, :operating_system,
                   :image, :vo, :expiration_date, :base_mpuri, :appid, :digest,
                   :image_list_identifier).new('id456', 'description', 'http://mp.uri.net', 'title2', 'group', 2048, 6, 'v01',
                                               'x86_64', 'Linux', image_proto, 'vo', date.to_i, 'http://basemp.uri.net', '185484',
                                               '1b56fa1', 'id12345'),
        Struct.new(:identifier, :description, :mpuri, :title, :group,
                   :ram, :core, :version, :architecture, :operating_system,
                   :image, :vo, :expiration_date, :base_mpuri, :appid, :digest,
                   :image_list_identifier).new('id789', 'description', 'http://mp.uri.net', 'title3', 'group', 2048, 6, 'v01',
                                               'x86_64', 'Linux', image_proto, 'vo', date.to_i, 'http://basemp.uri.net', '215485',
                                               '826c74ae', 'id12345')
      ]
    end

    before do
      allow(backend_connector.grpc_client).to receive(:appliances) { appliances_proto }
    end

    it 'returns list of appliances for specified image list identifier' do
      appliances = backend_connector.appliances(image_list_identifier)

      appliance = appliances['id123']
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
      expect(appliance.vo).to eq('vo')
      expect(appliance.expiration_date.to_date).to eq(date.to_date)
      expect(appliance.image_list_identifier).to eq('id12345')
      expect(appliance.base_mpuri).to eq('http://basemp.uri.net')
      expect(appliance.appid).to eq('564184')
      expect(appliance.digest).to eq('6dfe12a')

      appliance = appliances['id456']
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
      expect(appliance.vo).to eq('vo')
      expect(appliance.expiration_date.to_date).to eq(date.to_date)
      expect(appliance.image_list_identifier).to eq('id12345')
      expect(appliance.base_mpuri).to eq('http://basemp.uri.net')
      expect(appliance.appid).to eq('185484')
      expect(appliance.digest).to eq('1b56fa1')

      appliance = appliances['id789']
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
      expect(appliance.vo).to eq('vo')
      expect(appliance.expiration_date.to_date).to eq(date.to_date)
      expect(appliance.image_list_identifier).to eq('id12345')
      expect(appliance.base_mpuri).to eq('http://basemp.uri.net')
      expect(appliance.appid).to eq('215485')
      expect(appliance.digest).to eq('826c74ae')
    end

    it 'calls method on gRPC client instance' do
      backend_connector.appliances(image_list_identifier)
      expect(backend_connector.grpc_client).to have_received(:appliances) { appliances_proto }
    end
  end

  describe '.credentials' do
    context 'with enabled authentication' do
      before do
        Cloudkeeper::Settings[:authentication] = true
        Cloudkeeper::Settings[:certificate] = File.join(MOCK_DIR, 'auth', 'cert.pem')
        Cloudkeeper::Settings[:key] = File.join(MOCK_DIR, 'auth', 'key.pem')
        Cloudkeeper::Settings[:'backend-certificate'] = File.join(MOCK_DIR, 'auth', 'cert.pem')
      end

      it 'returns credentials' do
        expect(backend_connector.send(:credentials)).to be_instance_of GRPC::Core::ChannelCredentials
      end
    end

    context 'with disabled authentication' do
      before do
        Cloudkeeper::Settings[:authentication] = false
      end

      it 'returns insecure channel flag' do
        expect(backend_connector.send(:credentials)).to eq(:this_channel_is_insecure)
      end
    end
  end
end
