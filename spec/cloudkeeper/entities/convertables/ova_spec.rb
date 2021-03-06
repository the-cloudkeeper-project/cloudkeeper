describe Cloudkeeper::Entities::Convertables::Ova do
  subject(:convertable_instance_ova) do
    Class.new do
      attr_accessor :file, :format, :checksum
      include Cloudkeeper::Entities::Convertables::Convertable
      def initialize
        extend(Cloudkeeper::Entities::Convertables::Ova)
      end
    end.new
  end

  let(:convertable_instance_vmdk) do
    Class.new do
      attr_accessor :file, :format, :checksum
      include Cloudkeeper::Entities::Convertables::Convertable
    end.new
  end

  let(:convertable_instance_qcow2) do
    Class.new do
      attr_accessor :file, :format, :checksum
      include Cloudkeeper::Entities::Convertables::Convertable
    end.new
  end

  before do
    convertable_instance_ova.file = File.join(MOCK_DIR, 'image_conversions', 'image.ova')
    convertable_instance_ova.format = :ova
    convertable_instance_ova.checksum = 'f1e33fc55bdcb32149dd3e2472ecd6b55f243ac16ba4a348fb6fba26e9054dde95d4fd129fc8e168b7c223a6376' \
                                        'e07be2cbf73941cad41315e1da769fb36fec3'

    convertable_instance_vmdk.file = File.join(MOCK_DIR, 'image_conversions', 'image.vmdk')
    convertable_instance_vmdk.format = :vmdk
    convertable_instance_vmdk.checksum = '0ede16b0de18db9744e22f100178871a88f056a565c034fb3300b4e015cfb655e85a2d150a7a0d4392c50596ff' \
                                         '9a8150be59b55cd3cf5cd4f1dd3ac41c5ce30e'

    convertable_instance_qcow2.file = File.join(MOCK_DIR, 'image_conversions', 'image.qcow2')
    convertable_instance_qcow2.format = :qcow2
    convertable_instance_qcow2.checksum = '1f9f7ea530ac8200f7b29e6544b9933487361957b8272c4a30219b2639e1d2aa2731c3a792cfe042fd494590' \
                                          '9ed510f4882a28293ec37ac898e566c02d315b89'

    Cloudkeeper::Settings[:'qemu-img-binary'] = '/dummy/binary/qemu-img'
  end

  it "won't extend instance without file and format methods and Convertable module already included" do
    expect do
      Class.new do
        def initialize
          extend(Cloudkeeper::Entities::Convertables::Ova)
        end
      end.new
    end.to raise_error(Cloudkeeper::Errors::Convertables::ConvertabilityError)

    expect do
      Class.new do
        attr_accessor :file, :format, :checksum
        def initialize
          extend(Cloudkeeper::Entities::Convertables::Ova)
        end
      end.new
    end.to raise_error(Cloudkeeper::Errors::Convertables::ConvertabilityError)

    expect do
      Class.new do
        include Cloudkeeper::Entities::Convertables::Convertable
        def initialize
          extend(Cloudkeeper::Entities::Convertables::Ova)
        end
      end.new
    end.to raise_error(Cloudkeeper::Errors::Convertables::ConvertabilityError)
  end

  describe '.to_ova' do
    it 'returns itself' do
      expect(convertable_instance_ova.to_ova).to eq(convertable_instance_ova)
    end
  end

  describe '.archive_files' do
    let(:output) { "image.ovf\n#{File.basename(convertable_instance_vmdk.file)}\nimage.mf\n" }

    before do
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with('tar', '-t', '-f', convertable_instance_ova.file) { output }
    end

    it 'returns archive files in an array' do
      expect(convertable_instance_ova.send(:archive_files)).to \
        eq(['image.ovf', File.basename(convertable_instance_vmdk.file), 'image.mf'])
    end
  end

  describe '.disk_file' do
    let(:output) { "image.ovf\n#{File.basename(convertable_instance_vmdk.file)}\nimage.mf\n" }

    before do
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with('tar', '-t', '-f', convertable_instance_ova.file) { output }
    end

    it 'returns disk filename from archive' do
      expect(convertable_instance_ova.send(:disk_file)).to eq(File.basename(convertable_instance_vmdk.file))
    end
  end

  describe '.extract_disk' do
    let(:output) { "image.ovf\n#{File.basename(convertable_instance_vmdk.file)}\nimage.mf\n" }

    before do
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with('tar', '-t', '-f', convertable_instance_ova.file) { output }
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with('tar',
                                                                       '-x',
                                                                       '-f',
                                                                       convertable_instance_ova.file,
                                                                       '-C',
                                                                       File.join(MOCK_DIR, 'image_conversions'),
                                                                       File.basename(convertable_instance_vmdk.file))
    end

    it 'extracts disk file and returns its location' do
      expect(convertable_instance_ova.send(:extract_disk)).to eq(convertable_instance_vmdk.file)
    end

    context 'with wierdly named VMDK file' do
      let(:filename) { 'Some //wierd// filename.vmdk' }
      let(:output) { "image.ovf\n#{filename}\nimage.mf\n" }
      let(:sanitized) { File.join(MOCK_DIR, 'image_conversions', 'Some_wierd_filename.vmdk') }

      before do
        allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with('tar',
                                                                         '-x',
                                                                         '-f',
                                                                         convertable_instance_ova.file,
                                                                         '-C',
                                                                         File.join(MOCK_DIR, 'image_conversions'),
                                                                         filename)
        allow(File).to receive(:rename).with(File.join(MOCK_DIR, 'image_conversions', filename),
                                             sanitized)
      end

      it 'extracts disk file and returns its location sanitized' do
        expect(convertable_instance_ova.send(:extract_disk)).to eq(sanitized)
      end
    end
  end

  describe '.to_vmdk' do
    let(:output) { "image.ovf\n#{File.basename(convertable_instance_vmdk.file)}\nimage.mf\n" }

    before do
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with('tar', '-t', '-f', convertable_instance_ova.file) { output }
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with('tar',
                                                                       '-x',
                                                                       '-f',
                                                                       convertable_instance_ova.file,
                                                                       '-C',
                                                                       File.join(MOCK_DIR, 'image_conversions'),
                                                                       File.basename(convertable_instance_vmdk.file))
    end

    it 'converts image to VMDK format and returns ImageFile insatnce' do
      vmdk_image = convertable_instance_ova.to_vmdk
      expect(vmdk_image.file).to eq(convertable_instance_vmdk.file)
      expect(vmdk_image.format).to eq(convertable_instance_vmdk.format)
      expect(vmdk_image.checksum).to eq(convertable_instance_vmdk.checksum)
    end
  end

  describe '.convert' do
    let(:output) { "image.ovf\n#{File.basename(convertable_instance_vmdk.file)}\nimage.mf\n" }

    before do
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with('tar', '-t', '-f', convertable_instance_ova.file) { output }
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with('tar',
                                                                       '-x',
                                                                       '-f',
                                                                       convertable_instance_ova.file,
                                                                       '-C',
                                                                       File.join(MOCK_DIR, 'image_conversions'),
                                                                       File.basename(convertable_instance_vmdk.file))
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with(Cloudkeeper::Settings[:'qemu-img-binary'],
                                                                       'convert',
                                                                       '-f',
                                                                       'vmdk',
                                                                       '-O',
                                                                       'qcow2',
                                                                       convertable_instance_vmdk.file,
                                                                       convertable_instance_qcow2.file)
      allow(File).to receive(:delete).and_return(nil)
    end

    it 'converts image to specified format and returns new instance of ImageFile' do
      image_file = convertable_instance_ova.send(:convert, :qcow2)
      expect(image_file.file).to eq(convertable_instance_qcow2.file)
      expect(image_file.format).to eq(:qcow2)
      expect(image_file.checksum).to eq(convertable_instance_qcow2.checksum)
    end
  end

  describe '.convert_output_formats' do
    it 'returns an array of supported output fortmats' do
      expect(convertable_instance_ova.convert_output_formats).to eq(%i[raw qcow2 vdi ova])
    end
  end
end
