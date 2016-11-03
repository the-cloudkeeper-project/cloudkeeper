require 'spec_helper'

describe Cloudkeeper::Managers::ImageListManager do
  subject(:ilm) { Cloudkeeper::Managers::ImageListManager.new }

  before :example do
    VCR.configure do |config|
      config.cassette_library_dir = File.join(MOCK_DIR, 'cassettes')
      config.hook_into :webmock
    end
  end

  describe '#new' do
    it 'returns an instance of ImageListManager' do
      is_expected.to be_instance_of Cloudkeeper::Managers::ImageListManager
    end

    it 'prepares image_lists attribute as an empty array' do
      expect(ilm.image_lists).to be_instance_of Array
      expect(ilm.image_lists).to be_empty
    end

    it 'prepares openssl_store attribute as OpenSSL::X509::Store instance' do
      expect(ilm.openssl_store).to be_instance_of OpenSSL::X509::Store
    end

    context 'with custom CA directory' do
      let(:openssl_dummy_store) { instance_double OpenSSL::X509::Store }

      before :example do
        expect(OpenSSL::X509::Store).to receive(:new) { openssl_dummy_store }
        expect(openssl_dummy_store).to receive(:add_path).with('/some/ca/directory')
      end

      it 'prepares openssl_store attribute as OpenSSL::X509::Store instance with custom CA directory' do
        Cloudkeeper::Managers::ImageListManager.new ca_dir: '/some/ca/directory'
      end
    end

    context 'with invalid custom CA directory' do
      let(:openssl_dummy_store) { instance_double OpenSSL::X509::Store }

      before :example do
        expect(OpenSSL::X509::Store).to receive(:new) { openssl_dummy_store }
        expect(openssl_dummy_store).not_to receive(:add_path)
      end

      it 'prepares openssl_store attribute as OpenSSL::X509::Store instance without custom CA directory' do
        Cloudkeeper::Managers::ImageListManager.new ca_dir: nil
      end
    end
  end

  describe '.generate_filename' do
    let(:uri) { URI.parse 'https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-bbbb-b6a1-cc2f51319fa7:485' }
    let(:dir) { '/some/directory/' }

    it 'returns full path of sanitized filename constructed from given URI' do
      expect(ilm.send(:generate_filename, uri, dir)).to \
        eq('/some/directory/appdb.somewhere.netstorevoimage662b0e71-3e21-bbbb-b6a1-cc2f51319fa7485')
    end
  end

  describe '.verify_image_list!' do
    let(:pkcs7) { OpenSSL::PKCS7.read_smime(File.read(image_list_file)) }
    let(:ilm) { Cloudkeeper::Managers::ImageListManager.new ca_dir: File.join(MOCK_DIR, 'ca') }

    context 'with valid image list' do
      let(:image_list_file) { File.join(MOCK_DIR, 'imagelist01.signed') }

      it 'pass the verification test' do
        expect { ilm.send(:verify_image_list!, pkcs7, image_list_file) }.not_to raise_error
      end
    end

    context 'with invalid image list' do
      let(:image_list_file) { File.join(MOCK_DIR, 'imagelist_invalid.signed') }

      it 'raise ImageListVerificationError exception' do
        expect { ilm.send(:verify_image_list!, pkcs7, image_list_file) }.to \
          raise_error(Cloudkeeper::Errors::ImageListVerificationError)
      end
    end
  end

  describe '.load_image_list' do
    let(:ilm) { Cloudkeeper::Managers::ImageListManager.new ca_dir: File.join(MOCK_DIR, 'ca') }

    context 'with valid image list' do
      let(:image_list_file) { File.join(MOCK_DIR, 'imagelist01.signed') }
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

      it 'returns parsed image list as hash' do
        expect(ilm.send(:load_image_list, image_list_file)).to eq(image_list_hash)
      end
    end

    context 'with invalid image list' do
      let(:image_list_file) { File.join(MOCK_DIR, 'imagelist_invalid.signed') }

      it 'raise ImageListVerificationError exception' do
        expect { ilm.send(:load_image_list, image_list_file) }.to \
          raise_error(Cloudkeeper::Errors::ImageListVerificationError)
      end
    end
  end

  describe '#download_image_lists' do
    let(:tmpdir) { Dir.mktmpdir('cloudkeeper-test') }

    after :example do
      FileUtils.remove_entry tmpdir
    end

    context 'with basic auth' do
      it 'downloads and stores image list returning stored filename' do
        VCR.use_cassette('imagelist-basic-auth') do
          filename = ilm.send(:download_image_list, 'http://test:test@localhost:9292/imagelist-basic-auth.plain', tmpdir)

          expect(File.exist?(filename)).to be_truthy
          expect(filename).to eq(File.join(tmpdir.to_s, 'localhostimagelist-basic-auth.plain'))
        end
      end
    end

    context 'without basic auth' do
      it 'downloads and stores image list returning stored filename' do
        VCR.use_cassette('imagelist') do
          filename = ilm.send(:download_image_list, 'http://localhost:9292/imagelist.plain', tmpdir)

          expect(File.exist?(filename)).to be_truthy
          expect(filename).to eq(File.join(tmpdir.to_s, 'localhostimagelist.plain'))
        end
      end
    end
  end

  describe '.download_image_lists' do
    let(:ilm) { Cloudkeeper::Managers::ImageListManager.new ca_dir: File.join(MOCK_DIR, 'ca') }
    let(:urls) do
      [
        'http://localhost:9292/imagelist01.signed',
        'http://localhost:9292/imagelist02.signed',
        'http://localhost:9292/imagelist03.signed'
      ]
    end
    let(:expiration) { DateTime.new(2499, 12, 31, 22) }
    let(:attributes1) do
      { :'dc:description' => 'This version of CERNVM has been modified - default OS extended to 40GB of disk '\
        '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources',
        :'dc:identifier' => 'c0482bc2-bf41-5d49-cccc-a750174a186b',
        :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-cccc-a750174a186b:484/',
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
        :'ad:user:fullname' => 'Clark Kent',
        :'ad:user:guid' => '9d9dd6cf-b61a-cccc-b1df-b5731adf717c',
        :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/clark.kent',
        vo: 'some2.vo.net',
        expiration: expiration,
        image_list_identifier: '76fdee70-8119-5d33-cccc-3c57e1c60df1',
        :'dc:creator' => 'Applications Database',
        :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
        :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
        :'hv:email' => 'dontwriteme@please.net' }
    end
    let(:attributes2) do
      { :'dc:description' => '',
        :'dc:identifier' => '662b0e71-3e21-dddd-b6a1-cc2f51319fa7',
        :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-dddd-b6a1-cc2f51319fa7:485/',
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
        :'ad:user:fullname' => 'Oliver Queen',
        :'ad:user:guid' => 'e85470d8-2af9-dddd-8c26-0014c23dfd8c',
        :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/oliver.queen',
        vo: 'some2.vo.net',
        expiration: expiration,
        image_list_identifier: '76fdee70-8119-5d33-cccc-3c57e1c60df1',
        :'dc:creator' => 'Applications Database',
        :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
        :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
        :'hv:email' => 'dontwriteme@please.net' }
    end
    let(:attributes3) do
      { :'dc:description' => 'This version of CERNVM has been modified - default OS extended to 40GB of disk '\
        '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources',
        :'dc:identifier' => 'c0482bc2-bf41-5d49-gggg-a750174a186b',
        :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-gggg-a750174a186b:484/',
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
        :'ad:user:fullname' => 'Victor Stone',
        :'ad:user:guid' => '9d9dd6cf-b61a-gggg-b1df-b5731adf717c',
        :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/victor.stone',
        vo: 'some4.vo.net',
        expiration: expiration,
        image_list_identifier: '76fdee70-8119-5d33-gggg-3c57e1c60df1',
        :'dc:creator' => 'Applications Database',
        :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
        :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
        :'hv:email' => 'dontwriteme@please.net' }
    end
    let(:attributes4) do
      { :'dc:description' => '',
        :'dc:identifier' => '662b0e71-3e21-hhhh-b6a1-cc2f51319fa7',
        :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-hhhh-b6a1-cc2f51319fa7:485/',
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
        :'ad:user:fullname' => 'Billy Batson',
        :'ad:user:guid' => 'e85470d8-2af9-hhhh-8c26-0014c23dfd8c',
        :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/billy.batson',
        vo: 'some4.vo.net',
        expiration: expiration,
        image_list_identifier: '76fdee70-8119-5d33-gggg-3c57e1c60df1',
        :'dc:creator' => 'Applications Database',
        :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
        :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
        :'hv:email' => 'dontwriteme@please.net' }
    end
    let(:attributes5) do
      { :'dc:description' => 'This version of CERNVM has been modified - default OS extended to 40GB of disk '\
        '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources',
        :'dc:identifier' => 'c0482bc2-bf41-5d49-eeee-a750174a186b',
        :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-eeee-a750174a186b:484/',
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
        :'ad:user:fullname' => 'Arthur Curry',
        :'ad:user:guid' => '9d9dd6cf-b61a-eeee-b1df-b5731adf717c',
        :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/arthur.curry',
        vo: 'some3.vo.net',
        expiration: expiration,
        image_list_identifier: '76fdee70-8119-5d33-eeee-3c57e1c60df1',
        :'dc:creator' => 'Applications Database',
        :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
        :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
        :'hv:email' => 'dontwriteme@please.net' }
    end
    let(:attributes6) do
      { :'dc:description' => '',
        :'dc:identifier' => '662b0e71-3e21-ffff-b6a1-cc2f51319fa7',
        :'ad:mpuri' => 'https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-ffff-b6a1-cc2f51319fa7:485/',
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
        :'ad:user:fullname' => 'Ray Palmer',
        :'ad:user:guid' => 'e85470d8-2af9-ffff-8c26-0014c23dfd8c',
        :'ad:user:uri' => 'https://appdb.somewhere.net/store/person/ray.palmer',
        vo: 'some3.vo.net',
        expiration: expiration,
        image_list_identifier: '76fdee70-8119-5d33-eeee-3c57e1c60df1',
        :'dc:creator' => 'Applications Database',
        :'hv:ca' => '/DC=XXX/DC=YYY/CN=SOME TEST CA',
        :'hv:dn' => '/DC=XXX/DC=YYY/C=ZZZ/O=Hosts/O=AA.net/CN=some.unknown.source',
        :'hv:email' => 'dontwriteme@please.net' }
    end

    it 'downloads, parse and populates image lists from given urls' do
      VCR.use_cassette('download-image-lists') do
        ilm.download_image_lists(urls)

        il = ilm.image_lists[0]

        expect(il.identifier).to eq('76fdee70-8119-5d33-cccc-3c57e1c60df1')
        expect(il.creation_date).to eq(DateTime.new(2015, 6, 18, 21, 14))
        expect(il.description).to eq('This is a VO-wide image list for some2.vo.net VO.')
        expect(il.source).to eq('https://some.unknown.source/')
        expect(il.title).to eq('Dummy image list number 2.')

        appliance = il.appliances.first

        expect(appliance.identifier).to eq('c0482bc2-bf41-5d49-cccc-a750174a186b')
        expect(appliance.description).to eq('This version of CERNVM has been modified - default OS extended to 40GB of disk '\
      					    '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources')
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-cccc-a750174a186b:484/')
        expect(appliance.title).to eq('Image for CernVM [Scientific Linux/6.0/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to eq('1024')
        expect(appliance.core).to eq('4')
        expect(appliance.version).to eq('3.3.0-1')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux Scientific Linux 6.0')
        expect(appliance.vo).to eq('some2.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-cccc-3c57e1c60df1')
        expect(appliance.attributes).to eq(attributes1)

        appliance = il.appliances.last

        expect(appliance.identifier).to eq('662b0e71-3e21-dddd-b6a1-cc2f51319fa7')
        expect(appliance.description).to be_empty
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-dddd-b6a1-cc2f51319fa7:485/')
        expect(appliance.title).to eq('Image for CentOS 6 minimal [CentOS/6.x/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to be_nil
        expect(appliance.core).to be_nil
        expect(appliance.version).to eq('20141029')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux CentOS 6.6')
        expect(appliance.vo).to eq('some2.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-cccc-3c57e1c60df1')
        expect(appliance.attributes).to eq(attributes2)

        il = ilm.image_lists[1]

        expect(il.identifier).to eq('76fdee70-8119-5d33-gggg-3c57e1c60df1')
        expect(il.creation_date).to eq(DateTime.new(2015, 6, 18, 21, 14))
        expect(il.description).to eq('This is a VO-wide image list for some4.vo.net VO.')
        expect(il.source).to eq('https://some.unknown.source/')
        expect(il.title).to eq('Dummy image list number 4.')

        appliance = il.appliances.first

        expect(appliance.identifier).to eq('c0482bc2-bf41-5d49-gggg-a750174a186b')
        expect(appliance.description).to eq('This version of CERNVM has been modified - default OS extended to 40GB of disk '\
      					    '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources')
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-gggg-a750174a186b:484/')
        expect(appliance.title).to eq('Image for CernVM [Scientific Linux/6.0/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to eq('1024')
        expect(appliance.core).to eq('4')
        expect(appliance.version).to eq('3.3.0-1')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux Scientific Linux 6.0')
        expect(appliance.vo).to eq('some4.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-gggg-3c57e1c60df1')
        expect(appliance.attributes).to eq(attributes3)

        appliance = il.appliances.last

        expect(appliance.identifier).to eq('662b0e71-3e21-hhhh-b6a1-cc2f51319fa7')
        expect(appliance.description).to be_empty
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-hhhh-b6a1-cc2f51319fa7:485/')
        expect(appliance.title).to eq('Image for CentOS 6 minimal [CentOS/6.x/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to be_nil
        expect(appliance.core).to be_nil
        expect(appliance.version).to eq('20141029')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux CentOS 6.6')
        expect(appliance.vo).to eq('some4.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-gggg-3c57e1c60df1')
        expect(appliance.attributes).to eq(attributes4)

        il = ilm.image_lists[2]

        expect(il.identifier).to eq('76fdee70-8119-5d33-eeee-3c57e1c60df1')
        expect(il.creation_date).to eq(DateTime.new(2015, 6, 18, 21, 14))
        expect(il.description).to eq('This is a VO-wide image list for some3.vo.net VO.')
        expect(il.source).to eq('https://some.unknown.source/')
        expect(il.title).to eq('Dummy image list number 3.')

        appliance = il.appliances.first

        expect(appliance.identifier).to eq('c0482bc2-bf41-5d49-eeee-a750174a186b')
        expect(appliance.description).to eq('This version of CERNVM has been modified - default OS extended to 40GB of disk '\
      					    '- updated OpenNebula Cloud-Init driver to latest version 0.7.5 - enabled all Cloud-Init data sources')
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/c0482bc2-bf41-5d49-eeee-a750174a186b:484/')
        expect(appliance.title).to eq('Image for CernVM [Scientific Linux/6.0/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to eq('1024')
        expect(appliance.core).to eq('4')
        expect(appliance.version).to eq('3.3.0-1')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux Scientific Linux 6.0')
        expect(appliance.vo).to eq('some3.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-eeee-3c57e1c60df1')
        expect(appliance.attributes).to eq(attributes5)

        appliance = il.appliances.last

        expect(appliance.identifier).to eq('662b0e71-3e21-ffff-b6a1-cc2f51319fa7')
        expect(appliance.description).to be_empty
        expect(appliance.mpuri).to eq('https://appdb.somewhere.net/store/vo/image/662b0e71-3e21-ffff-b6a1-cc2f51319fa7:485/')
        expect(appliance.title).to eq('Image for CentOS 6 minimal [CentOS/6.x/KVM]')
        expect(appliance.group).to eq('General group')
        expect(appliance.ram).to be_nil
        expect(appliance.core).to be_nil
        expect(appliance.version).to eq('20141029')
        expect(appliance.architecture).to eq('x86_64')
        expect(appliance.operating_system).to eq('Linux CentOS 6.6')
        expect(appliance.vo).to eq('some3.vo.net')
        expect(appliance.expiration_date).to eq(expiration)
        expect(appliance.image_list_identifier).to eq('76fdee70-8119-5d33-eeee-3c57e1c60df1')
        expect(appliance.attributes).to eq(attributes6)
      end
    end
  end
end
