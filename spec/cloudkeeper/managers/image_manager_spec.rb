require 'spec_helper'
require 'tempfile'

describe Cloudkeeper::Managers::ImageManager do
  subject(:im) { described_class.new }

  describe '#new' do
    it 'returns an instance of ImageManager' do
      is_expected.to be_instance_of described_class
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

      it 'raise a PermissionDeniedError exception' do
        expect { described_class.check_file! file }.to raise_error(Cloudkeeper::Errors::PermissionDeniedError)
      end

      after do
        file.unlink
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

      it 'raise NoImageFormatRecognizedError exception' do
        outputs.each do |output|
          allow(described_class).to receive(:file_description).with(file) { output }
          expect { described_class.recognize_format(file) }.to \
            raise_error(Cloudkeeper::Errors::ImageFormat::NoFormatRecognizedError)
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
            raise_error(Cloudkeeper::Errors::ImageFormat::NoFormatRecognizedError)
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
            raise_error(Cloudkeeper::Errors::ImageFormat::NoFormatRecognizedError)
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

      it 'raise NoImageFormatRecognizedError exception' do
        outputs.each do |output|
          allow(described_class).to receive(:file_description).with(file) { output }
          expect { described_class.recognize_format(file) }.to \
            raise_error(Cloudkeeper::Errors::ImageFormat::NoFormatRecognizedError)
        end
      end
    end
  end

  describe '#file_description' do
    let(:file) { 'file' }
    let(:output) { 'some dummy output' }

    before do
      expect(Cloudkeeper::CommandExecutioner).to receive(:execute).with('file', '-b', file) { output }
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

    context 'if everything goes well' do
      it 'returns image format' do
        expect(described_class.format(file)).to eq(:qcow2)
      end
    end

    context 'with nonexisting file' do
      let(:file) { File.join('nonexisting', 'file') }

      it 'raises ImageFormatRecognitionError exception' do
        expect { described_class.format file }.to raise_error(Cloudkeeper::Errors::ImageFormat::RecognitionError)
      end
    end

    context 'with nonreadable file' do
      let(:file) do
        file = Tempfile.new('cloudkeeper-image')
        File.chmod(0o000, file.path)

        file
      end

      it 'raises ImageFormatRecognitionError exception' do
        expect { described_class.format file }.to raise_error(Cloudkeeper::Errors::ImageFormat::RecognitionError)
      end

      after do
        file.unlink
      end
    end

    context 'with nonexisting file' do
      let(:output) { 'unknown output' }

      it 'raises ImageFormatRecognitionError exception' do
        expect { described_class.format file }.to raise_error(Cloudkeeper::Errors::ImageFormat::RecognitionError)
      end
    end
  end
end

def load_outputs(file)
  File.readlines(File.join(MOCK_DIR, 'image_formats', file))
end
