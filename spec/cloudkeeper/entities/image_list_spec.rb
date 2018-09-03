require 'spec_helper'

describe Cloudkeeper::Entities::ImageList do
  subject(:image_list) { described_class.new 'identifier123', '2499-12-31T22:00:00Z' }

  describe '#new' do
    it 'returns an instance of ImageList' do
      expect(image_list).to be_instance_of described_class
    end

    it 'prepares appliances attribute as an hash instance' do
      expect(image_list.appliances).to be_instance_of Hash
    end

    it 'prepares appliances attribute as an empty hash' do
      expect(image_list.appliances).to be_empty
    end

    context 'with nil identifier' do
      it 'raises ArgumentError exception' do
        expect { described_class.new nil, '2499-12-31T22:00:00Z' }.to raise_error(Cloudkeeper::Errors::ArgumentError)
      end
    end

    context 'with nil expiration date' do
      it 'raises ArgumentError exception' do
        expect { described_class.new 'identifier123', nil }.to raise_error(Cloudkeeper::Errors::ArgumentError)
      end
    end
  end

  describe '.add_appliance' do
    context 'with invalid appliance' do
      it 'fails with ArgumentError exception' do
        expect { image_list.add_appliance nil }.to raise_error Cloudkeeper::Errors::ArgumentError
      end
    end

    context 'with valid appliance' do
      let(:appliance) { instance_double Cloudkeeper::Entities::Appliance }

      before do
        allow(appliance).to receive(:identifier).and_return('id123')
      end

      it 'adds appliance to image list' do
        image_list.add_appliance appliance
        expect(image_list.appliances).to have(1).items
      end
    end
  end

  describe '#prepare_appliance_hash' do
    let(:image_hash) { load_file 'image_list01.json', symbolize: true }
    let(:vo) { 'some.vo' }
    let(:image_list_identifier) { '76fdee70-8119-5d33-xxxx-3c57e1c60df1' }
    let(:endorser) { load_file 'image_list02.json', symbolize: true }
    let(:appliance_hash) { load_file 'image_list03.json', symbolize: true }

    context 'with all the data' do
      it 'creates full appliance hash' do
        expect(described_class.prepare_appliance_hash(image_hash, endorser, vo, \
                                                      image_list_identifier)).to eq(appliance_hash)
      end
    end

    context 'with missing image data' do
      let(:image_hash) { nil }
      let(:appliance_hash) { load_file 'image_list04.json', symbolize: true }

      it 'creates partial appliance hash' do
        expect(described_class.prepare_appliance_hash(image_hash, endorser, vo, \
                                                      image_list_identifier)).to eq(appliance_hash)
      end
    end

    context 'with missing endorser data' do
      let(:endorser) { nil }
      let(:appliance_hash) { load_file 'image_list13.json', symbolize: true }

      it 'creates partial appliance hash' do
        expect(described_class.prepare_appliance_hash(image_hash, endorser, vo, \
                                                      image_list_identifier)).to eq(appliance_hash)
      end
    end
  end

  describe '#populate_image_list' do
    context 'with invalid image list hash' do
      it 'raises InvalidImageListHashError exception' do
        expect { described_class.populate_image_list nil }.to raise_error(::Cloudkeeper::Errors::Parsing::InvalidImageListHashError)
      end
    end

    context 'with all the values' do
      let(:image_list_hash) { load_file 'image_list05.json', symbolize: true }

      it 'returns populated ImageList instance' do
        il = described_class.populate_image_list image_list_hash

        expect(il.identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(il.expiration_date).to eq(Time.new(2499, 12, 31, 22))
        expect(il.creation_date).to eq(Time.new(2015, 6, 18, 21, 14))
        expect(il.description).to eq('This is a VO-wide image list for some1.vo.net VO.')
        expect(il.source).to eq('https://some.unknown.source/')
        expect(il.title).to eq('Dummy image list number 1.')
      end
    end

    context 'without some optional values' do
      let(:image_list_hash) { load_file 'image_list06.json', symbolize: true }

      it 'returns populated ImageList instance' do
        il = described_class.populate_image_list image_list_hash

        expect(il.identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(il.expiration_date).to eq(Time.new(2499, 12, 31, 22))
        expect(il.creation_date).to eq(Time.new(2015, 6, 18, 21, 14))
        expect(il.description).to eq('This is a VO-wide image list for some1.vo.net VO.')
        expect(il.source).to be_nil
        expect(il.title).to eq('Dummy image list number 1.')
      end
    end

    context 'without mandatory values' do
      let(:image_list_hash) { load_file 'image_list14.json', symbolize: true }

      it 'raises InvalidImageListHashError exception' do
        expect { described_class.populate_image_list image_list_hash }.to \
          raise_error(::Cloudkeeper::Errors::Parsing::InvalidImageListHashError)
      end
    end
  end

  describe '#populate_appliances!' do
    let(:expiration) { Time.new(2499, 12, 31, 22) }
    let(:image_list_hash) { load_file 'image_list07.json', symbolize: true }

    before do
      image_list.identifier = '76fdee70-8119-5d33-aaaa-3c57e1c60df1'
    end

    context 'with two appliances in the hash' do
      it 'will contain two populated Appliance instances' do
        described_class.populate_appliances!(image_list, image_list_hash)

        appliance = image_list.appliances[image_list.appliances.keys.first]

        expect(appliance.identifier).to eq('c0482bc2-bf41-5d49-aaaa-a750174a186b')
        expect(appliance.description).to eq('This version of CERNVM has been modified - default OS extended to 40GB of disk '\
          '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources')
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-aaaa-a750174a186b:484/')
        expect(appliance.title).to eq('Image for CernVM [Scientific Linux/6.0/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to eq('512')
        expect(appliance.core).to eq('1')
        expect(appliance.version).to eq('3.3.0-1')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux Scientific Linux 6.0')
        expect(appliance.vo).to eq('some1.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(appliance.base_mpuri).to eq('https://appdb.somewhere.net/store/vm/image/2a5451eb-91f3-aaaa-95a7-9cff7362d553:6450:1469784811/')
        expect(appliance.appid).to eq('993')
        expect(appliance.digest).to eq('1ce845c07468bd628b74518a6b5a98fe2b1510b6ff8c23b0c848493c19da6289244ffdf7fa9f66c097951dfea'\
                                       'e8f6f950eca2b9fecc50f217f81695785ed1272')

        appliance = image_list.appliances[image_list.appliances.keys.last]

        expect(appliance.identifier).to eq('662b0e71-3e21-bbbb-b6a1-cc2f51319fa7')
        expect(appliance.description).to be_empty
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-bbbb-b6a1-cc2f51319fa7:485/')
        expect(appliance.title).to eq('Image for CentOS 6 minimal [CentOS/6.x/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to be_nil
        expect(appliance.core).to be_nil
        expect(appliance.version).to eq('20141029')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux CentOS 6.6')
        expect(appliance.vo).to eq('some1.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(appliance.base_mpuri).to eq('https://appdb.somewhere.net/store/vm/image/662b0e71-3e21-bbbb-b6a1-cc2f51319fa7:485/')
        expect(appliance.appid).to eq('111')
        expect(appliance.digest).to eq('a9f49096f292726ae236844dd91653c2deb47fb36dad6cde4906112243496ebb2bdaaf165c0116e29c6e87eda'\
                                       '65d08eadc6352888f4a32d376b59d01c3815f12')
      end
    end
  end

  describe '#from_hash' do
    context 'with image list in form of hash' do
      let(:expiration) { Time.new(2499, 12, 31, 22) }
      let(:image_list_hash) { load_file 'image_list10.json' }

      it 'returns fully populated image list' do
        il = described_class.from_hash image_list_hash

        expect(il.identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(il.creation_date).to eq(Time.new(2015, 6, 18, 21, 14))
        expect(il.description).to eq('This is a VO-wide image list for some1.vo.net VO.')
        expect(il.source).to eq('https://some.unknown.source/')
        expect(il.title).to eq('Dummy image list number 1.')

        appliance = il.appliances[il.appliances.keys.first]

        expect(appliance.identifier).to eq('c0482bc2-bf41-5d49-aaaa-a750174a186b')
        expect(appliance.description).to eq('This version of CERNVM has been modified - default OS extended to 40GB of disk '\
          '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources')
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-aaaa-a750174a186b:484/')
        expect(appliance.title).to eq('Image for CernVM [Scientific Linux/6.0/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to eq('512')
        expect(appliance.core).to eq('1')
        expect(appliance.version).to eq('3.3.0-1')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux Scientific Linux 6.0')
        expect(appliance.vo).to eq('some1.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(appliance.base_mpuri).to eq('https://appdb.somewhere.net/store/vm/image/2a5451eb-91f3-aaaa-95a7-9cff7362d553:6450:1469784811/')
        expect(appliance.appid).to eq('993')

        appliance = il.appliances[il.appliances.keys.last]

        expect(appliance.identifier).to eq('662b0e71-3e21-bbbb-b6a1-cc2f51319fa7')
        expect(appliance.description).to be_empty
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-bbbb-b6a1-cc2f51319fa7:485/')
        expect(appliance.title).to eq('Image for CentOS 6 minimal [CentOS/6.x/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to be_nil
        expect(appliance.core).to be_nil
        expect(appliance.version).to eq('20141029')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux CentOS 6.6')
        expect(appliance.vo).to eq('some1.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(appliance.base_mpuri).to eq('https://appdb.somewhere.net/store/vm/image/662b0e71-3e21-bbbb-b6a1-cc2f51319fa7:485/')
        expect(appliance.appid).to eq('111')
      end
    end
  end

  describe '.expired?' do
    context 'with expired image list' do
      before do
        image_list.expiration_date = Time.new(1991, 10, 10)
      end

      it 'returns true' do
        expect(image_list).to be_expired
      end
    end

    context 'with non-expired image list' do
      it 'returns false' do
        expect(image_list).not_to be_expired
      end
    end
  end
end
