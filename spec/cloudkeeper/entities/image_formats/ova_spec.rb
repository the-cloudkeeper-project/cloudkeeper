describe Cloudkeeper::Entities::ImageFormats::Ova do
  subject(:ova_class) { Class.new { extend Cloudkeeper::Entities::ImageFormats::Ova } }

  before do
    allow(Cloudkeeper::CommandExecutioner).to receive(:execute) { output }
  end

  describe '#ova?' do
    context 'with ova image file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'image.ova') }
      let(:output) { "image.ovf\nimage.vmdk\n" }

      it 'returns true' do
        expect(ova_class).to be_ova(file)
      end
    end

    context 'with fake ova image file - missing vmdk file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image01.ova') }
      let(:output) { "dummy-file\nimage.ovf\n" }

      it 'returns false' do
        expect(ova_class).not_to be_ova(file)
      end
    end

    context 'with fake ova image file - missing ovf file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image02.ova') }
      let(:output) { "dummy-file\nimage.vmdk\n" }

      it 'returns false' do
        expect(ova_class).not_to be_ova(file)
      end
    end

    context 'with fake ova image file - missing both ovf and vmdk file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image03.ova') }
      let(:output) { "dummy-file\n" }

      it 'returns false' do
        expect(ova_class).not_to be_ova(file)
      end
    end

    context 'with fake ova image file - not an archive' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image04.ova') }

      before do
        allow(Cloudkeeper::CommandExecutioner).to receive(:execute).and_raise(Cloudkeeper::Errors::CommandExecutionError)
      end

      it 'raises a CommandExecutionError exception' do
        expect { ova_class.ova?(file) }.to raise_error(Cloudkeeper::Errors::Image::Format::Ova::OvaFormatError)
      end
    end

    context 'with fake ova image file - too many files' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image05.ova') }
      let(:output) { File.read(File.join(MOCK_DIR, 'image_formats', 'fake-image05-output')) }

      it 'raises a CommandExecutionError exception' do
        expect { ova_class.ova?(file) }.to raise_error(Cloudkeeper::Errors::Image::Format::Ova::OvaFormatError)
      end
    end
  end
end
