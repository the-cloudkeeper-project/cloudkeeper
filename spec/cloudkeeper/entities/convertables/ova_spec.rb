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

  let(:command) { instance_double(Mixlib::ShellOut) }

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

    allow(command).to receive(:run_command)
    allow(command).to receive(:error?) { false }
    allow(command).to receive(:command) { 'command' }
    allow(command).to receive(:stderr) { 'stderr' }

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
    before do
      expect(Mixlib::ShellOut).to receive(:new).with('tar', '-t', '-f', convertable_instance_ova.file) { command }
      allow(command).to receive(:stdout) { "image.ovf\n#{File.basename(convertable_instance_vmdk.file)}\nimage.mf\n" }
    end

    context 'with failed command list' do
      before do
        allow(command).to receive(:error?) { true }
      end

      it 'raises CommandExecutionError exception' do
        expect { convertable_instance_ova.send(:archive_files) }.to raise_error(Cloudkeeper::Errors::CommandExecutionError)
      end
    end

    context 'run without error' do
      it 'returns archive files in an array' do
        expect(convertable_instance_ova.send(:archive_files)).to \
          eq(['image.ovf', File.basename(convertable_instance_vmdk.file), 'image.mf'])
      end
    end
  end

  describe '.disk_file' do
    before do
      allow(Mixlib::ShellOut).to receive(:new).with('tar', '-t', '-f', convertable_instance_ova.file) { command }
      allow(command).to receive(:stdout) { "image.ovf\n#{File.basename(convertable_instance_vmdk.file)}\nimage.mf\n" }
    end

    it 'returns disk filename from archive' do
      expect(convertable_instance_ova.send(:disk_file)).to eq(File.basename(convertable_instance_vmdk.file))
    end
  end

  describe '.extract_disk' do
    before do
      allow(Mixlib::ShellOut).to receive(:new).with('tar', '-t', '-f', convertable_instance_ova.file) { command }
      allow(Mixlib::ShellOut).to receive(:new).with('tar',
                                                    '-x',
                                                    '-f',
                                                    convertable_instance_ova.file,
                                                    '-C',
                                                    File.join(MOCK_DIR, 'image_conversions'),
                                                    File.basename(convertable_instance_vmdk.file)) { command }
      allow(command).to receive(:stdout) { "image.ovf\n#{File.basename(convertable_instance_vmdk.file)}\nimage.mf\n" }
    end

    context 'with failed extract command' do
      before do
        allow(command).to receive(:error?).and_return(true, false)
      end

      it 'raises CommandExecutionError exception' do
        expect { convertable_instance_ova.send(:extract_disk) }.to raise_error(Cloudkeeper::Errors::CommandExecutionError)
      end
    end

    context 'run without error' do
      it 'extracts disk file and returns its location' do
        expect(convertable_instance_ova.send(:extract_disk)).to eq(convertable_instance_vmdk.file)
      end
    end
  end

  describe '.to_vmdk' do
    before do
      allow(Mixlib::ShellOut).to receive(:new).with('tar', '-t', '-f', convertable_instance_ova.file) { command }
      allow(Mixlib::ShellOut).to receive(:new).with('tar',
                                                    '-x',
                                                    '-f',
                                                    convertable_instance_ova.file,
                                                    '-C',
                                                    File.join(MOCK_DIR, 'image_conversions'),
                                                    File.basename(convertable_instance_vmdk.file)) { command }
      allow(command).to receive(:stdout) { "image.ovf\n#{File.basename(convertable_instance_vmdk.file)}\nimage.mf\n" }
    end

    it 'converts image to VMDK format and returns ImageFile insatnce' do
      vmdk_image = convertable_instance_ova.to_vmdk
      expect(vmdk_image.file).to eq(convertable_instance_vmdk.file)
      expect(vmdk_image.format).to eq(convertable_instance_vmdk.format)
      expect(vmdk_image.checksum).to eq(convertable_instance_vmdk.checksum)
      expect(vmdk_image.original).to be_falsy
    end
  end

  describe '.convert' do
    before do
      allow(Mixlib::ShellOut).to receive(:new).with('tar', '-t', '-f', convertable_instance_ova.file) { command }
      allow(Mixlib::ShellOut).to receive(:new).with('tar',
                                                    '-x',
                                                    '-f',
                                                    convertable_instance_ova.file,
                                                    '-C',
                                                    File.join(MOCK_DIR, 'image_conversions'),
                                                    File.basename(convertable_instance_vmdk.file)) { command }
      allow(Mixlib::ShellOut).to receive(:new).with(Cloudkeeper::Settings[:'qemu-img-binary'],
                                                    'convert',
                                                    '-f',
                                                    'vmdk',
                                                    '-O',
                                                    'qcow2',
                                                    convertable_instance_vmdk.file,
                                                    convertable_instance_qcow2.file) { command }
      allow(command).to receive(:stdout) { "image.ovf\n#{File.basename(convertable_instance_vmdk.file)}\nimage.mf\n" }
      allow(File).to receive(:delete) { nil }
    end

    it 'converts image to specified format and returns new instance of ImageFile' do
      image_file = convertable_instance_ova.send(:convert, :qcow2)
      expect(image_file.file).to eq(convertable_instance_qcow2.file)
      expect(image_file.format).to eq(:qcow2)
      expect(image_file.checksum).to eq(convertable_instance_qcow2.checksum)
      expect(image_file.original).to be_falsy
    end
  end
end
