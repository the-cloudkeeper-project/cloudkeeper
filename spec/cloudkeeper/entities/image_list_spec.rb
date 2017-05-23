require 'spec_helper'

describe Cloudkeeper::Entities::ImageList do
  subject(:image_list) { described_class.new 'identifier123', '2499-12-31T22:00:00Z' }

  describe '#new' do
    it 'returns an instance of ImageList' do
      is_expected.to be_instance_of described_class
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
        allow(appliance).to receive(:identifier) { 'id123' }
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
    let(:expiration) { DateTime.new(2015, 6, 18, 21, 14) }
    let(:image_list_identifier) { '76fdee70-8119-5d33-xxxx-3c57e1c60df1' }
    let(:endorser) { load_file 'image_list02.json', symbolize: true }
    let(:appliance_hash) { load_file 'image_list03.json', symbolize: true }

    before do
      appliance_hash[:expiration] = expiration
    end

    context 'with all the data' do
      it 'creates full appliance hash' do
        expect(described_class.prepare_appliance_hash(image_hash, endorser, expiration, vo, \
                                                      image_list_identifier)).to eq(appliance_hash)
      end
    end

    context 'with missing image data' do
      let(:image_hash) { nil }
      let(:appliance_hash) { load_file 'image_list04.json', symbolize: true }

      it 'creates partial appliance hash' do
        expect(described_class.prepare_appliance_hash(image_hash, endorser, expiration, vo, \
                                                      image_list_identifier)).to eq(appliance_hash)
      end
    end

    context 'with missing endorser data' do
      let(:endorser) { nil }
      let(:appliance_hash) { load_file 'image_list13.json', symbolize: true }

      it 'creates partial appliance hash' do
        expect(described_class.prepare_appliance_hash(image_hash, endorser, expiration, vo, \
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
        expect(il.expiration_date).to eq(DateTime.new(2499, 12, 31, 22))
        expect(il.creation_date).to eq(DateTime.new(2015, 6, 18, 21, 14))
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
        expect(il.expiration_date).to eq(DateTime.new(2499, 12, 31, 22))
        expect(il.creation_date).to eq(DateTime.new(2015, 6, 18, 21, 14))
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
    let(:expiration) { DateTime.new(2499, 12, 31, 22) }
    let(:image_list_hash) { load_file 'image_list07.json', symbolize: true }
    let(:attributes1) { load_file 'image_list08.json' }
    let(:attributes2) { load_file 'image_list09.json' }

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
        expect(appliance.attributes).to eq(attributes1)

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
        expect(appliance.attributes).to eq(attributes2)
      end
    end
  end

  describe '#from_hash' do
    context 'with image list in form of hash' do
      let(:expiration) { DateTime.new(2499, 12, 31, 22) }
      let(:image_list_hash) { load_file 'image_list10.json' }
      let(:attributes1) { load_file 'image_list11.json' }
      let(:attributes2) { load_file 'image_list12.json' }

      it 'returns fully populated image list' do
        il = described_class.from_hash image_list_hash

        expect(il.identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(il.creation_date).to eq(DateTime.new(2015, 6, 18, 21, 14))
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
        expect(appliance.attributes).to eq(attributes1)

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
        expect(appliance.attributes).to eq(attributes2)
      end
    end
  end

  describe '#parse_date' do
    context 'with nil date' do
      it 'returns empty string' do
        expect(described_class.parse_date(nil)).to eq('')
      end
    end

    context 'with empty date' do
      it 'returns empty string' do
        expect(described_class.parse_date('')).to eq('')
      end
    end

    context 'with real date' do
      it 'returns parsed DateTime instance' do
        expect(described_class.parse_date('2015-06-18T21:14:00Z')).to eq(DateTime.new(2015, 6, 18, 21, 14))
      end
    end
  end

  describe '.expired?' do
    context 'with expired image list' do
      before do
        image_list.expiration_date = DateTime.new(1991, 10, 10)
      end

      it 'returns true' do
        expect(image_list.expired?).to be_truthy
      end
    end

    context 'with non-expired image list' do
      it 'returns false' do
        expect(image_list.expired?).to be_falsy
      end
    end
  end
end
