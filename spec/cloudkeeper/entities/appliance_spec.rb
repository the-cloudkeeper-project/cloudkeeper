require 'spec_helper'

describe Cloudkeeper::Entities::Appliance do
  subject(:appliance) { described_class.new }

  let(:hash) { load_file 'appliance01.json', symbolize: true }

  describe '#new' do
    it 'returns instance of Appliance' do
      is_expected.to be_instance_of described_class
    end

    it 'prepares attributes attribute as a hash instance' do
      expect(appliance.attributes).to be_instance_of Hash
    end

    it 'prepares attributes attribute as an empty hash' do
      expect(appliance.attributes).to be_empty
    end
  end

  describe '#populate_attributes!' do
    it 'copies all values from hash to attributes attribute' do
      described_class.populate_attributes!(appliance, hash)
      expect(appliance.attributes).to eq(hash)
    end
  end

  describe '#check_appliance_hash!' do
    context 'with mandatory attributes missing' do
      before do
        hash[:'dc:identifier'] = nil
      end

      it 'raises an InvalidApplianceHashError exceptiong' do
        expect { described_class.check_appliance_hash! hash }.to \
          raise_error ::Cloudkeeper::Errors::Parsing::InvalidApplianceHashError
      end
    end

    context 'with all mandatory attributes are available' do
      it 'keeps quite when ' do
        expect { described_class.check_appliance_hash! hash }.not_to raise_error
      end
    end
  end

  describe '#construct_name!' do
    context 'with all name attributes available' do
      it 'sets appliance operating system to full name' do
        described_class.construct_name!(appliance, hash)
        expect(appliance.operating_system).to eq('Linux Other TinyCoreLinux')
      end
    end

    context 'with "sl:os" attribute missing' do
      before do
        hash[:'sl:os'] = nil
      end

      it 'sets appliance operating system to partial name' do
        described_class.construct_name!(appliance, hash)
        expect(appliance.operating_system).to eq('Other TinyCoreLinux')
      end
    end

    context 'with "sl:osname" attribute missing' do
      before do
        hash[:'sl:osname'] = nil
      end

      it 'sets appliance operating system to partial name' do
        described_class.construct_name!(appliance, hash)
        expect(appliance.operating_system).to eq('Linux TinyCoreLinux')
      end
    end

    context 'with no attributes available' do
      before do
        hash[:'sl:os'] = nil
        hash[:'sl:osname'] = nil
        hash[:'sl:osversion'] = nil
      end

      it 'sets appliance operating system to empty string' do
        described_class.construct_name!(appliance, hash)
        expect(appliance.operating_system).to be_empty
      end
    end
  end

  describe '#populate_appliance' do
    context 'with hash with correct values' do
      it 'populates and returns Appliance instance' do
        appliance = described_class.populate_appliance hash

        expect(appliance.identifier).to eq('2a5451eb-91f3-46a2-95a7-9cff7362d553')
        expect(appliance.description).to eq('This is a special Virtual Appliance entry used only for monitoring purposes.')
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vm/image/2a5451eb-91f3-aaaa-95a7-9cff7362d553:6450:1469784811/')
        expect(appliance.title).to eq('Some Image')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to eq(2048)
        expect(appliance.core).to eq(4)
        expect(appliance.version).to eq('0.0.5867')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux Other TinyCoreLinux')
        expect(appliance.vo).to eq('some.dummy.vo')
        expect(appliance.expiration_date).to eq('2016-10-25T15:57:45+02:00')
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
      end
    end

    context 'with hash with missing values' do
      before do
        hash[:'ad:core_recommended'] = nil
        hash[:'hv:version'] = nil
      end

      it 'populates and returns Image instance with missing values as nils' do
        appliance = described_class.populate_appliance hash

        expect(appliance.identifier).to eq('2a5451eb-91f3-46a2-95a7-9cff7362d553')
        expect(appliance.description).to eq('This is a special Virtual Appliance entry used only for monitoring purposes.')
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vm/image/2a5451eb-91f3-aaaa-95a7-9cff7362d553:6450:1469784811/')
        expect(appliance.title).to eq('Some Image')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to eq(2048)
        expect(appliance.core).to be_nil
        expect(appliance.version).to be_nil
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux Other TinyCoreLinux')
        expect(appliance.vo).to eq('some.dummy.vo')
        expect(appliance.expiration_date).to eq('2016-10-25T15:57:45+02:00')
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
      end
    end

    context 'with empty hash' do
      let(:hash) { {} }

      it 'populates and returns Image instance with missing values as nils' do
        appliance = described_class.populate_appliance hash

        expect(appliance.identifier).to be_nil
        expect(appliance.description).to be_nil
        expect(appliance.mpuri).to be_nil
        expect(appliance.title).to be_nil
        expect(appliance.group).to be_nil
        expect(appliance.ram).to be_nil
        expect(appliance.core).to be_nil
        expect(appliance.version).to be_nil
        expect(appliance.architecture).to be_nil
        expect(appliance.operating_system).to be_empty
        expect(appliance.vo).to be_nil
        expect(appliance.expiration_date).to be_nil
        expect(appliance.image_list_identifier).to be_nil
      end
    end

    context 'with hash with redundant values' do
      before do
        hash['redundant_key'] = 'redundant_value'
      end

      it 'populates and returns Appliance instance ignoring redundant values' do
        appliance = described_class.populate_appliance hash

        expect(appliance.identifier).to eq('2a5451eb-91f3-46a2-95a7-9cff7362d553')
        expect(appliance.description).to eq('This is a special Virtual Appliance entry used only for monitoring purposes.')
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vm/image/2a5451eb-91f3-aaaa-95a7-9cff7362d553:6450:1469784811/')
        expect(appliance.title).to eq('Some Image')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to eq(2048)
        expect(appliance.core).to eq(4)
        expect(appliance.version).to eq('0.0.5867')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux Other TinyCoreLinux')
        expect(appliance.vo).to eq('some.dummy.vo')
        expect(appliance.expiration_date).to eq('2016-10-25T15:57:45+02:00')
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
      end
    end
  end

  describe '#from_hash' do
    let(:hash) { load_file 'appliance02.json' }

    it 'creates Appliance instance from given hash' do
      appliance = described_class.from_hash hash

      expect(appliance.identifier).to eq('2a5451eb-91f3-46a2-95a7-9cff7362d553')
      expect(appliance.description).to eq('This is a special Virtual Appliance entry used only for monitoring purposes.')
      expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vm/image/2a5451eb-91f3-aaaa-95a7-9cff7362d553:6450:1469784811/')
      expect(appliance.title).to eq('Some Image')
      expect(appliance.group).to eq('General group')
      expect(appliance.ram).to eq(2048)
      expect(appliance.core).to eq(4)
      expect(appliance.version).to eq('0.0.5867')
      expect(appliance.architecture).to eq('x86_64')
      expect(appliance.operating_system).to eq('Linux Other TinyCoreLinux')
      expect(appliance.vo).to eq('some.dummy.vo')
      expect(appliance.expiration_date).to eq('2016-10-25T15:57:45+02:00')
      expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
      expect(appliance.image.size).to eq(42)
      expect(appliance.image.uri).to eq('http://some.uri.net/some/path')
      expect(appliance.image.checksum).to eq('81a106e4f352b2ff21c691280d9bfd3dfafdbe07154f414ae563d1786ff55a254e66e94e6644ae1f175'\
                                            '70a502cd46d3e7f2ece043fcd211818eed871f4aaef53')
    end
  end
end
