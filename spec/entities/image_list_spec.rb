require 'spec_helper'

describe Cloudkeeper::Entities::ImageList do
  subject(:image_list) { Cloudkeeper::Entities::ImageList.new }

  describe '#new' do
    it 'returns an instance of ImageList' do
      is_expected.to be_instance_of Cloudkeeper::Entities::ImageList
    end

    it 'prepares appliances attributes as an empty array' do
      expect(image_list.appliances).to be_instance_of Array
      expect(image_list.appliances).to be_empty
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

      it 'adds appliance to image list' do
        expect(image_list.appliances).to be_empty
        image_list.add_appliance appliance
        expect(image_list.appliances).to have(1).items
      end
    end
  end

  describe '#prepare_appliance_hash' do
    let(:image_hash) do
      { :'hv:image' =>
        { :'dc:description' => 'This version of CERNVM has been modified - default OS extended to 40GB of disk '\
          '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources',
          :'dc:identifier' => 'c0482bc2-bf41-5d49-aaaa-a750174a186b',
          :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-aaaa-a750174a186b:484/',
          :'dc:title' => 'Image for CernVM [Scientific Linux/6.0/KVM]',
          :'ad:group' => 'General group',
          :'hv:hypervisor' => 'KVM',
          :'hv:format' => 'OVA',
          :'hv:ram_minimum' => '512',
          :'ad:ram_recommended' => '1024',
          :'hv:core_minimum' => '1',
          :'ad:core_recommended' => '4',
          :'hv:size' => '121243136',
          :'hv:uri' => 'https://appdb.somewhere.net/images/base/CERNVM/3.3.0/CERNVM-3.3.0-40GB.ova',
          :'hv:version' => '3.3.0-1',
          :'sl:arch' => 'x86_64',
          :'sl:checksum:sha512' => '5c548a09467df6ff6ee77659a8cfe15115ef366b94baa30c47e079b711119652a17c8f947ab437e70c799480b4'\
          'b5dc3d68a3b22581b3318db35dd3364e83dab0',
          :'sl:comments' => '',
          :'sl:os' => 'Linux',
          :'sl:osname' => 'Scientific Linux',
          :'sl:osversion' => '6.0',
          :'ad:user:fullname' => 'Bruce Wayne',
          :'ad:user:guid' => '9d9dd6cf-b61a-aaaa-b1df-b5731adf717c',
          :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/bruce.wayne' } }
    end
    let(:vo) { 'some.vo' }
    let(:expiration) { Date.new }
    let(:image_list_identifier) { '76fdee70-8119-5d33-xxxx-3c57e1c60df1' }
    let(:endorser) do
      { :'hv:x509' =>
        { :'dc:creator' => 'Applications Database',
          :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
          :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
          :'hv:email' => 'dontwriteme@please.net' } }
    end
    let(:appliance_hash) do
      { :'dc:description' => 'This version of CERNVM has been modified - default OS extended to 40GB of disk '\
        '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources',
        :'dc:identifier' => 'c0482bc2-bf41-5d49-aaaa-a750174a186b',
        :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-aaaa-a750174a186b:484/',
        :'dc:title' => 'Image for CernVM [Scientific Linux/6.0/KVM]',
        :'ad:group' => 'General group',
        :'hv:hypervisor' => 'KVM',
        :'hv:format' => 'OVA',
        :'hv:ram_minimum' => '512',
        :'ad:ram_recommended' => '1024',
        :'hv:core_minimum' => '1',
        :'ad:core_recommended' => '4',
        :'hv:size' => '121243136',
        :'hv:uri' => 'https://appdb.somewhere.net/images/base/CERNVM/3.3.0/CERNVM-3.3.0-40GB.ova',
        :'hv:version' => '3.3.0-1',
        :'sl:arch' => 'x86_64',
        :'sl:checksum:sha512' => '5c548a09467df6ff6ee77659a8cfe15115ef366b94baa30c47e079b711119652a17c8f947ab437e70c799480b4'\
        'b5dc3d68a3b22581b3318db35dd3364e83dab0',
        :'sl:comments' => '',
        :'sl:os' => 'Linux',
        :'sl:osname' => 'Scientific Linux',
        :'sl:osversion' => '6.0',
        :'ad:user:fullname' => 'Bruce Wayne',
        :'ad:user:guid' => '9d9dd6cf-b61a-aaaa-b1df-b5731adf717c',
        :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/bruce.wayne',
        vo: 'some.vo',
        expiration: expiration,
        image_list_identifier: '76fdee70-8119-5d33-xxxx-3c57e1c60df1',
        :'dc:creator' => 'Applications Database',
        :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
        :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
        :'hv:email' => 'dontwriteme@please.net' }
    end
    context 'witch all the data' do
      it 'creates full appliance hash' do
        expect(Cloudkeeper::Entities::ImageList.prepare_appliance_hash(image_hash, endorser, expiration, vo, \
                                                                       image_list_identifier)).to eq(appliance_hash)
      end
    end

    context 'with missing image data' do
      let(:image_hash) { nil }
      let(:appliance_hash) do
        { vo: 'some.vo',
          expiration: expiration,
          image_list_identifier: '76fdee70-8119-5d33-xxxx-3c57e1c60df1',
          :'dc:creator' => 'Applications Database',
          :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
          :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
          :'hv:email' => 'dontwriteme@please.net' }
      end

      it 'creates partial appliance hash' do
        expect(Cloudkeeper::Entities::ImageList.prepare_appliance_hash(image_hash, endorser, expiration, vo, \
                                                                       image_list_identifier)).to eq(appliance_hash)
      end
    end

    context 'with missing endorser data' do
      let(:endorser) { nil }
      let(:appliance_hash) do
        { :'dc:description' => 'This version of CERNVM has been modified - default OS extended to 40GB of disk '\
          '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources',
          :'dc:identifier' => 'c0482bc2-bf41-5d49-aaaa-a750174a186b',
          :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-aaaa-a750174a186b:484/',
          :'dc:title' => 'Image for CernVM [Scientific Linux/6.0/KVM]',
          :'ad:group' => 'General group',
          :'hv:hypervisor' => 'KVM',
          :'hv:format' => 'OVA',
          :'hv:ram_minimum' => '512',
          :'ad:ram_recommended' => '1024',
          :'hv:core_minimum' => '1',
          :'ad:core_recommended' => '4',
          :'hv:size' => '121243136',
          :'hv:uri' => 'https://appdb.somewhere.net/images/base/CERNVM/3.3.0/CERNVM-3.3.0-40GB.ova',
          :'hv:version' => '3.3.0-1',
          :'sl:arch' => 'x86_64',
          :'sl:checksum:sha512' => '5c548a09467df6ff6ee77659a8cfe15115ef366b94baa30c47e079b711119652a17c8f947ab437e70c799480b4'\
          'b5dc3d68a3b22581b3318db35dd3364e83dab0',
          :'sl:comments' => '',
          :'sl:os' => 'Linux',
          :'sl:osname' => 'Scientific Linux',
          :'sl:osversion' => '6.0',
          :'ad:user:fullname' => 'Bruce Wayne',
          :'ad:user:guid' => '9d9dd6cf-b61a-aaaa-b1df-b5731adf717c',
          :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/bruce.wayne',
          vo: 'some.vo',
          expiration: expiration,
          image_list_identifier: '76fdee70-8119-5d33-xxxx-3c57e1c60df1' }
      end

      it 'creates partial appliance hash' do
        expect(Cloudkeeper::Entities::ImageList.prepare_appliance_hash(image_hash, endorser, expiration, vo, \
                                                                       image_list_identifier)).to eq(appliance_hash)
      end
    end
  end

  describe '#populate_image_list' do
    context 'with invalid image list hash' do
      it 'returns empty ImageList instance' do
        il = Cloudkeeper::Entities::ImageList.populate_image_list nil

        expect(il.identifier).to be_nil
        expect(il.creation_date).to be_nil
        expect(il.description).to be_nil
        expect(il.source).to be_nil
        expect(il.title).to be_nil
      end
    end

    context 'with all the values' do
      let(:image_list_hash) do
        { :'dc:date:created' => '2015-06-18T21:14:00Z',
          :'dc:description' => 'This is a VO-wide image list for some1.vo.net VO.',
          :'dc:identifier' => '76fdee70-8119-5d33-aaaa-3c57e1c60df1',
          :'dc:source' => 'https://some.unknown.source/',
          :'dc:title' => 'Dummy image list number 1.' }
      end

      it 'returns populated ImageList instance' do
        il = Cloudkeeper::Entities::ImageList.populate_image_list image_list_hash

        expect(il.identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(il.creation_date).to eq(DateTime.new(2015, 6, 18, 21, 14))
        expect(il.description).to eq('This is a VO-wide image list for some1.vo.net VO.')
        expect(il.source).to eq('https://some.unknown.source/')
        expect(il.title).to eq('Dummy image list number 1.')
      end
    end

    context 'with all the values' do
      let(:image_list_hash) do
        { :'dc:date:created' => '2015-06-18T21:14:00Z',
          :'dc:description' => 'This is a VO-wide image list for some1.vo.net VO.',
          :'dc:title' => 'Dummy image list number 1.' }
      end

      it 'returns populated ImageList instance' do
        il = Cloudkeeper::Entities::ImageList.populate_image_list image_list_hash

        expect(il.identifier).to be_nil
        expect(il.creation_date).to eq(DateTime.new(2015, 6, 18, 21, 14))
        expect(il.description).to eq('This is a VO-wide image list for some1.vo.net VO.')
        expect(il.source).to be_nil
        expect(il.title).to eq('Dummy image list number 1.')
      end
    end
  end

  describe '#populate_appliances!' do
    let(:expiration) { DateTime.new(2499, 12, 31, 22) }
    let(:image_list_hash) do
      { :'dc:date:created' => '2015-06-18T21:14:00Z',
        :'dc:date:expires' => '2499-12-31T22:00:00Z',
        :'dc:description' => 'This is a VO-wide image list for some1.vo.net VO.',
        :'dc:identifier' => '76fdee70-8119-5d33-aaaa-3c57e1c60df1',
        :'dc:source' => 'https://some.unknown.source/',
        :'dc:title' => 'Dummy image list number 1.',
        :'ad:vo' => 'some1.vo.net',
        :'hv:endorser' =>
        { :'hv:x509' =>
          { :'dc:creator' => 'Applications Database',
            :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
            :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
            :'hv:email' => 'dontwriteme@please.net' } },
        :'hv:images' =>
        [
          { :'hv:image' =>
            { :'dc:description' => 'This version of CERNVM has been modified - default OS extended to 40GB of disk '\
              '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources',
              :'dc:identifier' => 'c0482bc2-bf41-5d49-aaaa-a750174a186b',
              :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-aaaa-a750174a186b:484/',
              :'dc:title' => 'Image for CernVM [Scientific Linux/6.0/KVM]',
              :'ad:group' => 'General group',
              :'hv:hypervisor' => 'KVM',
              :'hv:format' => 'OVA',
              :'hv:ram_minimum' => '512',
              :'ad:ram_recommended' => '1024',
              :'hv:core_minimum' => '1',
              :'ad:core_recommended' => '4',
              :'hv:size' => '121243136',
              :'hv:uri' => 'https://appdb.somewhere.net/images/base/CERNVM/3.3.0/CERNVM-3.3.0-40GB.ova',
              :'hv:version' => '3.3.0-1',
              :'sl:arch' => 'x86_64',
              :'sl:checksum:sha512' => '5c548a09467df6ff6ee77659a8cfe15115ef366b94baa30c47e079b711119652a17c8f947ab437e70c799480b4'\
              'b5dc3d68a3b22581b3318db35dd3364e83dab0',
              :'sl:comments' => '',
              :'sl:os' => 'Linux',
              :'sl:osname' => 'Scientific Linux',
              :'sl:osversion' => '6.0',
              :'ad:user:fullname' => 'Bruce Wayne',
              :'ad:user:guid' => '9d9dd6cf-b61a-aaaa-b1df-b5731adf717c',
              :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/bruce.wayne' } },
          { :'hv:image' =>
            { :'dc:description' => '',
              :'dc:identifier' => '662b0e71-3e21-bbbb-b6a1-cc2f51319fa7',
              :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-bbbb-b6a1-cc2f51319fa7:485/',
              :'dc:title' => 'Image for CentOS 6 minimal [CentOS/6.x/KVM]',
              :'ad:group' => 'General group',
              :'hv:hypervisor' => 'KVM',
              :'hv:format' => 'OVA',
              :'hv:size' => '581816320',
              :'hv:uri' => 'https://appdb.somewhere.net/images/base/CentOS-6.x-x86_64/20141029/CentOS-6.5-20141029.ova',
              :'hv:version' => '20141029',
              :'sl:arch' => 'x86_64',
              :'sl:checksum:sha512' => '02a2b436e8f10c22527795c33bf623a1a0ef2e7036166e8831f653c3662f8f2222821f4751d774947e32a85465'\
              '4ff645097c47da236e46ad54806c6fc72a29ce',
              :'sl:comments' => '',
              :'sl:os' => 'Linux',
              :'sl:osname' => 'CentOS',
              :'sl:osversion' => '6.6',
              :'ad:user:fullname' => 'Barry Allen',
              :'ad:user:guid' => 'e85470d8-2af9-bbbb-8c26-0014c23dfd8c',
              :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/barry.allen' } }
        ],
        :'hv:uri' => 'https://appdb.somewhere.net/store/vo/some1.vo.net/image.list',
        :'hv:version' => '20150618211400' }
    end
    let(:attributes1) do
      { :'dc:description' => 'This version of CERNVM has been modified - default OS extended to 40GB of disk '\
        '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources',
        :'dc:identifier' => 'c0482bc2-bf41-5d49-aaaa-a750174a186b',
        :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-aaaa-a750174a186b:484/',
        :'dc:title' => 'Image for CernVM [Scientific Linux/6.0/KVM]',
        :'ad:group' => 'General group',
        :'hv:hypervisor' => 'KVM',
        :'hv:format' => 'OVA',
        :'hv:ram_minimum' => '512',
        :'ad:ram_recommended' => '1024',
        :'hv:core_minimum' => '1',
        :'ad:core_recommended' => '4',
        :'hv:size' => '121243136',
        :'hv:uri' => 'https://appdb.somewhere.net/images/base/CERNVM/3.3.0/CERNVM-3.3.0-40GB.ova',
        :'hv:version' => '3.3.0-1',
        :'sl:arch' => 'x86_64',
        :'sl:checksum:sha512' => '5c548a09467df6ff6ee77659a8cfe15115ef366b94baa30c47e079b711119652a17c8f947ab437e70c799480b4'\
        'b5dc3d68a3b22581b3318db35dd3364e83dab0',
        :'sl:comments' => '',
        :'sl:os' => 'Linux',
        :'sl:osname' => 'Scientific Linux',
        :'sl:osversion' => '6.0',
        :'ad:user:fullname' => 'Bruce Wayne',
        :'ad:user:guid' => '9d9dd6cf-b61a-aaaa-b1df-b5731adf717c',
        :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/bruce.wayne',
        vo: 'some1.vo.net',
        expiration: expiration,
        image_list_identifier: '76fdee70-8119-5d33-aaaa-3c57e1c60df1',
        :'dc:creator' => 'Applications Database',
        :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
        :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
        :'hv:email' => 'dontwriteme@please.net' }
    end
    let(:attributes2) do
      { :'dc:description' => '',
        :'dc:identifier' => '662b0e71-3e21-bbbb-b6a1-cc2f51319fa7',
        :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-bbbb-b6a1-cc2f51319fa7:485/',
        :'dc:title' => 'Image for CentOS 6 minimal [CentOS/6.x/KVM]',
        :'ad:group' => 'General group',
        :'hv:hypervisor' => 'KVM',
        :'hv:format' => 'OVA',
        :'hv:size' => '581816320',
        :'hv:uri' => 'https://appdb.somewhere.net/images/base/CentOS-6.x-x86_64/20141029/CentOS-6.5-20141029.ova',
        :'hv:version' => '20141029',
        :'sl:arch' => 'x86_64',
        :'sl:checksum:sha512' => '02a2b436e8f10c22527795c33bf623a1a0ef2e7036166e8831f653c3662f8f2222821f4751d774947e32a85465'\
        '4ff645097c47da236e46ad54806c6fc72a29ce',
        :'sl:comments' => '',
        :'sl:os' => 'Linux',
        :'sl:osname' => 'CentOS',
        :'sl:osversion' => '6.6',
        :'ad:user:fullname' => 'Barry Allen',
        :'ad:user:guid' => 'e85470d8-2af9-bbbb-8c26-0014c23dfd8c',
        :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/barry.allen',
        vo: 'some1.vo.net',
        expiration: expiration,
        image_list_identifier: '76fdee70-8119-5d33-aaaa-3c57e1c60df1',
        :'dc:creator' => 'Applications Database',
        :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
        :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
        :'hv:email' => 'dontwriteme@please.net' }
    end

    before :example do
      image_list.identifier = '76fdee70-8119-5d33-aaaa-3c57e1c60df1'
    end

    context 'with two appliances in the hash' do
      it 'will contain two populated Appliance instances' do
        Cloudkeeper::Entities::ImageList.populate_appliances!(image_list, image_list_hash)

        appliance = image_list.appliances.first

        expect(appliance.identifier).to eq('c0482bc2-bf41-5d49-aaaa-a750174a186b')
        expect(appliance.description).to eq('This version of CERNVM has been modified - default OS extended to 40GB of disk '\
          '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources')
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-aaaa-a750174a186b:484/')
        expect(appliance.title).to eq('Image for CernVM [Scientific Linux/6.0/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to eq('1024')
        expect(appliance.core).to eq('4')
        expect(appliance.version).to eq('3.3.0-1')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux Scientific Linux 6.0')
        expect(appliance.vo).to eq('some1.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(appliance.attributes).to eq(attributes1)

        appliance = image_list.appliances.last

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
      let(:image_list_hash) do
        { 'hv:imagelist' =>
          { 'dc:date:created' => '2015-06-18T21:14:00Z',
            'dc:date:expires' => '2499-12-31T22:00:00Z',
            'dc:description' => 'This is a VO-wide image list for some1.vo.net VO.',
            'dc:identifier' => '76fdee70-8119-5d33-aaaa-3c57e1c60df1',
            'dc:source' => 'https://some.unknown.source/',
            'dc:title' => 'Dummy image list number 1.',
            'ad:vo' => 'some1.vo.net',
            'hv:endorser' =>
            { 'hv:x509' =>
              { 'dc:creator' => 'Applications Database',
                'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
                'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
                'hv:email' => 'dontwriteme@please.net' } },
            'hv:images' =>
            [
              { 'hv:image' =>
                { 'dc:description' => 'This version of CERNVM has been modified - default OS extended to 40GB of disk '\
                  '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources',
                  'dc:identifier' => 'c0482bc2-bf41-5d49-aaaa-a750174a186b',
                  'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-aaaa-a750174a186b:484/',
                  'dc:title' => 'Image for CernVM [Scientific Linux/6.0/KVM]',
                  'ad:group' => 'General group',
                  'hv:hypervisor' => 'KVM',
                  'hv:format' => 'OVA',
                  'hv:ram_minimum' => '512',
                  'ad:ram_recommended' => '1024',
                  'hv:core_minimum' => '1',
                  'ad:core_recommended' => '4',
                  'hv:size' => '121243136', 'hv:uri' => 'https://appdb.somewhere.net/images/base/CERNVM/3.3.0/CERNVM-3.3.0-40GB.ova',
                  'hv:version' => '3.3.0-1',
                  'sl:arch' => 'x86_64',
                  'sl:checksum:sha512' => '5c548a09467df6ff6ee77659a8cfe15115ef366b94baa30c47e079b711119652a17c8f947ab437e70c799480b4'\
                  'b5dc3d68a3b22581b3318db35dd3364e83dab0',
                  'sl:comments' => '',
                  'sl:os' => 'Linux',
                  'sl:osname' => 'Scientific Linux',
                  'sl:osversion' => '6.0',
                  'ad:user:fullname' => 'Bruce Wayne',
                  'ad:user:guid' => '9d9dd6cf-b61a-aaaa-b1df-b5731adf717c',
                  'ad:user:uri' => 'https://appdb.somewhere.net/store/person/bruce.wayne' } },
              { 'hv:image' =>
                { 'dc:description' => '',
                  'dc:identifier' => '662b0e71-3e21-bbbb-b6a1-cc2f51319fa7',
                  'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-bbbb-b6a1-cc2f51319fa7:485/',
                  'dc:title' => 'Image for CentOS 6 minimal [CentOS/6.x/KVM]',
                  'ad:group' => 'General group',
                  'hv:hypervisor' => 'KVM',
                  'hv:format' => 'OVA',
                  'hv:size' => '581816320',
                  'hv:uri' => 'https://appdb.somewhere.net/images/base/CentOS-6.x-x86_64/20141029/CentOS-6.5-20141029.ova',
                  'hv:version' => '20141029',
                  'sl:arch' => 'x86_64',
                  'sl:checksum:sha512' => '02a2b436e8f10c22527795c33bf623a1a0ef2e7036166e8831f653c3662f8f2222821f4751d774947e32a85465'\
                  '4ff645097c47da236e46ad54806c6fc72a29ce',
                  'sl:comments' => '',
                  'sl:os' => 'Linux',
                  'sl:osname' => 'CentOS',
                  'sl:osversion' => '6.6',
                  'ad:user:fullname' => 'Barry Allen',
                  'ad:user:guid' => 'e85470d8-2af9-bbbb-8c26-0014c23dfd8c',
                  'ad:user:uri' => 'https://appdb.somewhere.net/store/person/barry.allen' } }
            ],
            'hv:uri' => 'https://appdb.somewhere.net/store/vo/some1.vo.net/image.list',
            'hv:version' => '20150618211400' } }
      end
      let(:attributes1) do
        { :'dc:description' => 'This version of CERNVM has been modified - default OS extended to 40GB of disk '\
          '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources',
          :'dc:identifier' => 'c0482bc2-bf41-5d49-aaaa-a750174a186b',
          :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-aaaa-a750174a186b:484/',
          :'dc:title' => 'Image for CernVM [Scientific Linux/6.0/KVM]',
          :'ad:group' => 'General group',
          :'hv:hypervisor' => 'KVM',
          :'hv:format' => 'OVA',
          :'hv:ram_minimum' => '512',
          :'ad:ram_recommended' => '1024',
          :'hv:core_minimum' => '1',
          :'ad:core_recommended' => '4',
          :'hv:size' => '121243136',
          :'hv:uri' => 'https://appdb.somewhere.net/images/base/CERNVM/3.3.0/CERNVM-3.3.0-40GB.ova',
          :'hv:version' => '3.3.0-1',
          :'sl:arch' => 'x86_64',
          :'sl:checksum:sha512' => '5c548a09467df6ff6ee77659a8cfe15115ef366b94baa30c47e079b711119652a17c8f947ab437e70c799480b4'\
          'b5dc3d68a3b22581b3318db35dd3364e83dab0',
          :'sl:comments' => '',
          :'sl:os' => 'Linux',
          :'sl:osname' => 'Scientific Linux',
          :'sl:osversion' => '6.0',
          :'ad:user:fullname' => 'Bruce Wayne',
          :'ad:user:guid' => '9d9dd6cf-b61a-aaaa-b1df-b5731adf717c',
          :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/bruce.wayne',
          vo: 'some1.vo.net',
          expiration: expiration,
          image_list_identifier: '76fdee70-8119-5d33-aaaa-3c57e1c60df1',
          :'dc:creator' => 'Applications Database',
          :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
          :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
          :'hv:email' => 'dontwriteme@please.net' }
      end
      let(:attributes2) do
        { :'dc:description' => '',
          :'dc:identifier' => '662b0e71-3e21-bbbb-b6a1-cc2f51319fa7',
          :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-bbbb-b6a1-cc2f51319fa7:485/',
          :'dc:title' => 'Image for CentOS 6 minimal [CentOS/6.x/KVM]',
          :'ad:group' => 'General group',
          :'hv:hypervisor' => 'KVM',
          :'hv:format' => 'OVA',
          :'hv:size' => '581816320',
          :'hv:uri' => 'https://appdb.somewhere.net/images/base/CentOS-6.x-x86_64/20141029/CentOS-6.5-20141029.ova',
          :'hv:version' => '20141029',
          :'sl:arch' => 'x86_64',
          :'sl:checksum:sha512' => '02a2b436e8f10c22527795c33bf623a1a0ef2e7036166e8831f653c3662f8f2222821f4751d774947e32a85465'\
          '4ff645097c47da236e46ad54806c6fc72a29ce',
          :'sl:comments' => '',
          :'sl:os' => 'Linux',
          :'sl:osname' => 'CentOS',
          :'sl:osversion' => '6.6',
          :'ad:user:fullname' => 'Barry Allen',
          :'ad:user:guid' => 'e85470d8-2af9-bbbb-8c26-0014c23dfd8c',
          :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/barry.allen',
          vo: 'some1.vo.net',
          expiration: expiration,
          image_list_identifier: '76fdee70-8119-5d33-aaaa-3c57e1c60df1',
          :'dc:creator' => 'Applications Database',
          :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
          :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
          :'hv:email' => 'dontwriteme@please.net' }
      end

      it 'returns fully populated image list' do
        il = Cloudkeeper::Entities::ImageList.from_hash image_list_hash

        expect(il.identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(il.creation_date).to eq(DateTime.new(2015, 6, 18, 21, 14))
        expect(il.description).to eq('This is a VO-wide image list for some1.vo.net VO.')
        expect(il.source).to eq('https://some.unknown.source/')
        expect(il.title).to eq('Dummy image list number 1.')

        appliance = il.appliances.first

        expect(appliance.identifier).to eq('c0482bc2-bf41-5d49-aaaa-a750174a186b')
        expect(appliance.description).to eq('This version of CERNVM has been modified - default OS extended to 40GB of disk '\
          '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources')
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-aaaa-a750174a186b:484/')
        expect(appliance.title).to eq('Image for CernVM [Scientific Linux/6.0/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to eq('1024')
        expect(appliance.core).to eq('4')
        expect(appliance.version).to eq('3.3.0-1')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux Scientific Linux 6.0')
        expect(appliance.vo).to eq('some1.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-aaaa-3c57e1c60df1')
        expect(appliance.attributes).to eq(attributes1)

        appliance = il.appliances.last

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
end
