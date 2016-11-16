describe Cloudkeeper::Entities::ImageFormats::Ova do
  subject(:ova_class) { Class.new { extend Cloudkeeper::Entities::ImageFormats::Ova } }
  let(:command) { instance_double(Mixlib::ShellOut) }

  before do
    allow(Mixlib::ShellOut).to receive(:new) { command }
    allow(command).to receive(:run_command)
    allow(command).to receive(:error?) { false }
    allow(command).to receive(:command) { 'command' }
    allow(command).to receive(:stderr) { 'stderr' }
  end

  describe '#ova?' do
    context 'with ova image file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'image.ova') }

      before do
        allow(command).to receive(:stdout) { "image.ovf\nimage.vmdk\n" }
      end

      it 'returns true' do
        expect(ova_class.ova?(file)).to be_truthy
      end
    end

    context 'with fake ova image file - missing vmdk file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image01.ova') }

      before do
        allow(command).to receive(:stdout) { "dummy-file\nimage.ovf\n" }
      end

      it 'returns false' do
        expect(ova_class.ova?(file)).to be_falsy
      end
    end

    context 'with fake ova image file - missing ovf file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image02.ova') }

      before do
        allow(command).to receive(:stdout) { "dummy-file\nimage.vmdk\n" }
      end

      it 'returns false' do
        expect(ova_class.ova?(file)).to be_falsy
      end
    end

    context 'with fake ova image file - missing both ovf and vmdk file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image03.ova') }

      before do
        allow(command).to receive(:stdout) { "dummy-file\n" }
      end

      it 'returns false' do
        expect(ova_class.ova?(file)).to be_falsy
      end
    end

    context 'with fake ova image file - not an archive' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image04.ova') }

      before do
        expect(command).to receive(:error?) { true }
      end

      it 'raises a CommandExecutionError exception' do
        expect { ova_class.ova?(file) }.to raise_error(Cloudkeeper::Errors::CommandExecutionError)
      end
    end

    context 'with fake ova image file - too many files' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image05.ova') }

      before do
        allow(command).to receive(:stdout) { File.read(File.join(MOCK_DIR, 'image_formats', 'fake-image05-output')) }
      end

      it 'raises a CommandExecutionError exception' do
        expect { ova_class.ova?(file) }.to raise_error(Cloudkeeper::Errors::InvalidArchiveError)
      end
    end
  end
end
