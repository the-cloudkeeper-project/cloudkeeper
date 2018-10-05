require 'spec_helper'
require 'tempfile'

describe Cloudkeeper::Managers::ImageManager do
  subject(:im) { described_class.new }

  describe '#new' do
    it 'returns an instance of ImageManager' do
      expect(im).to be_instance_of described_class
    end
  end

  describe '#check_file!' do
    let(:file) { File.join(MOCK_DIR, 'image') }

    context 'with existing readable file' do
      it 'doesn\'t raise an exception' do
        expect { described_class.check_file! file }.not_to raise_error
      end
    end

    context 'with nonexisting file' do
      let(:file) { File.join(MOCK_DIR, 'nonexisting', 'image') }

      it 'raise a NoSuchFileError exception' do
        expect { described_class.check_file! file }.to raise_error(Cloudkeeper::Errors::NoSuchFileError)
      end
    end

    context 'with unreadable file' do
      let(:file) do
        file = Tempfile.new('cloudkeeper-image')
        File.chmod(0o000, file.path)

        file
      end

      after do
        file.unlink
      end

      it 'raise a PermissionDeniedError exception' do
        expect { described_class.check_file! file }.to raise_error(Cloudkeeper::Errors::PermissionDeniedError)
      end
    end
  end

  describe '#recognize_format' do
    let(:file) { File.join(MOCK_DIR, 'image_formats', 'image.ova') }

    context 'with ova image' do
      let(:outputs) { load_outputs 'ova' }

      it 'recognizes image as OVA image' do
        outputs.each do |output|
          allow(described_class).to receive(:file_description).with(file) { output }
          expect(described_class.recognize_format(file)).to eq(:ova)
        end
      end
    end

    context 'with fake ova image' do
      let(:outputs) { load_outputs 'ova' }
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image01.ova') }

      it 'raise NoImage::FormatRecognizedError exception' do
        outputs.each do |output|
          allow(described_class).to receive(:file_description).with(file) { output }
          expect { described_class.recognize_format(file) }.to \
            raise_error(Cloudkeeper::Errors::Image::Format::NoFormatRecognizedError)
        end
      end
    end

    context 'with fake ova image' do
      let(:outputs) { load_outputs 'ova' }
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image02.ova') }

      it 'recognizes image as OVA image' do
        outputs.each do |output|
          allow(described_class).to receive(:file_description).with(file) { output }
          expect { described_class.recognize_format(file) }.to \
            raise_error(Cloudkeeper::Errors::Image::Format::NoFormatRecognizedError)
        end
      end
    end

    context 'with fake ova image' do
      let(:outputs) { load_outputs 'ova' }
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image03.ova') }

      it 'recognizes image as OVA image' do
        outputs.each do |output|
          allow(described_class).to receive(:file_description).with(file) { output }
          expect { described_class.recognize_format(file) }.to \
            raise_error(Cloudkeeper::Errors::Image::Format::NoFormatRecognizedError)
        end
      end
    end

    context 'with vmdk image' do
      let(:outputs) { load_outputs 'vmdk' }

      it 'recognizes image as VMDK image' do
        outputs.each do |output|
          allow(described_class).to receive(:file_description).with(file) { output }
          expect(described_class.recognize_format(file)).to eq(:vmdk)
        end
      end
    end

    context 'with qcow2 image' do
      let(:outputs) { load_outputs 'qcow2' }

      it 'recognizes image as QCOW2 image' do
        outputs.each do |output|
          allow(described_class).to receive(:file_description).with(file) { output }
          expect(described_class.recognize_format(file)).to eq(:qcow2)
        end
      end
    end

    context 'with raw image' do
      let(:outputs) { load_outputs 'raw' }

      it 'recognizes image as RAW image' do
        outputs.each do |output|
          allow(described_class).to receive(:file_description).with(file) { output }
          expect(described_class.recognize_format(file)).to eq(:raw)
        end
      end
    end

    context 'with unknown image' do
      let(:outputs) { load_outputs 'unknown' }

      it 'raise NoImage::FormatRecognizedError exception' do
        outputs.each do |output|
          allow(described_class).to receive(:file_description).with(file) { output }
          expect { described_class.recognize_format(file) }.to \
            raise_error(Cloudkeeper::Errors::Image::Format::NoFormatRecognizedError)
        end
      end
    end
  end

  describe '#file_description' do
    let(:file) { 'file' }
    let(:output) { 'some dummy output' }

    before do
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with('file', '-b', file) { output }
    end

    it 'returns file description' do
      expect(described_class.file_description(file)).to eq(output)
    end
  end

  describe '#format' do
    let(:file) { File.join(MOCK_DIR, 'image_formats', 'ova') }
    let(:output) { 'QEMU QCOW Image (v3), 20971520 bytes' }

    before do
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with('file', '-b', file) { output }
    end

    context 'when everything goes well' do
      it 'returns image format' do
        expect(described_class.format(file)).to eq(:qcow2)
      end
    end

    context 'with nonexisting file' do
      let(:file) { File.join('nonexisting', 'file') }

      it 'raises Image::FormatRecognitionError exception' do
        expect { described_class.format file }.to raise_error(Cloudkeeper::Errors::Image::Format::RecognitionError)
      end
    end

    context 'with nonreadable file' do
      let(:file) do
        file = Tempfile.new('cloudkeeper-image')
        File.chmod(0o000, file.path)

        file
      end

      after do
        file.unlink
      end

      it 'raises Image::FormatRecognitionError exception' do
        expect { described_class.format file }.to raise_error(Cloudkeeper::Errors::Image::Format::RecognitionError)
      end
    end

    context 'with nonexisting file' do
      let(:output) { 'unknown output' }

      it 'raises Image::FormatRecognitionError exception' do
        expect { described_class.format file }.to raise_error(Cloudkeeper::Errors::Image::Format::RecognitionError)
      end
    end
  end

  describe '#generate_filename' do
    let(:uri) { URI.parse('http://some.nonexistent.server/path1/path2/file.ext') }

    before do
      Cloudkeeper::Settings[:'image-dir'] = '/image/output/directory/'
    end

    it 'returns full path of file, image will be download to' do
      expect(described_class.generate_filename(uri)).to eq('/image/output/directory/file.ext')
    end
  end

  describe '#secure_download_image' do
    let(:url) { 'http://localhost:9292/image.ext' }
    let(:tmpdir) { Dir.mktmpdir('cloudkeeper-test') }
    let(:checksum) do
      '9a8093f874bdf4c19b6deacd2208e347292452df008a61d815dcd8395a2487e263364a85ca569d71c27dd9e' \
      '349fd31227094644c39e9a734b199b2dbdefa9c35'
    end

    after do
      FileUtils.remove_entry tmpdir
    end

    before do
      Cloudkeeper::Settings[:'image-dir'] = tmpdir
      allow(described_class).to receive(:format).and_return(:qcow2)
    end

    context 'with invalid url' do
      let(:url) { 'NOT_AN_URL' }

      it 'raise InvalidURLError exception' do
        expect { described_class.secure_download_image url, checksum }.to raise_error(Cloudkeeper::Errors::Image::DownloadError)
      end
    end

    context 'with invalid checksum', :vcr do
      let(:checksum) do
        '9a8093f874bdf4c19b6deacd2208e347292452df008a61d815dcd8395a2487e263364a85ca569d71c27dd9e' \
        '349fd31227094644c39e9a734b199b2dbdefa9c30'
      end

      it 'raise ChecksumError exception' do
        expect { described_class.secure_download_image(url, checksum) }.to raise_error(Cloudkeeper::Errors::Image::ChecksumError)
      end
    end

    context 'with valid url and checksum', :vcr do
      it 'returns populated image file instance' do
        image_file = described_class.secure_download_image(url, checksum)
        expect(image_file.file).to eq(File.join(tmpdir, 'image.ext'))
        expect(image_file.format).to eq(:qcow2)
        expect(image_file.checksum).to eq(checksum)
        expect(image_file.size).to eq(524_288)
      end
    end
  end
end

def load_outputs(file)
  File.readlines(File.join(MOCK_DIR, 'image_formats', file))
end
