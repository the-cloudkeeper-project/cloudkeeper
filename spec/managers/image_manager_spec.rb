require 'spec_helper'
require 'tempfile'

describe Cloudkeeper::Managers::ImageManager do
  subject(:im) { Cloudkeeper::Managers::ImageManager.new }

  describe '#new' do
    it 'returns an instance of ImageManager' do
      is_expected.to be_instance_of Cloudkeeper::Managers::ImageManager
    end
  end

  describe '#check_file!' do
    let(:file) { File.join(MOCK_DIR, 'image') }

    context 'with existing readable file' do
      it 'doesn\'t raise an exception' do
        expect { Cloudkeeper::Managers::ImageManager.check_file! file }.not_to raise_error
      end
    end

    context 'with nonexisting file' do
      let(:file) { File.join(MOCK_DIR, 'nonexisting', 'image') }

      it 'raise a NoSuchFileError exception' do
        expect { Cloudkeeper::Managers::ImageManager.check_file! file }.to raise_error(Cloudkeeper::Errors::NoSuchFileError)
      end
    end

    context 'with unreadable file' do
      let(:file) do
        file = Tempfile.new('cloudkeeper-image')
        File.chmod(0o000, file.path)

        file
      end

      it 'raise a PermissionDeniedError exception' do
        expect { Cloudkeeper::Managers::ImageManager.check_file! file }.to raise_error(Cloudkeeper::Errors::PermissionDeniedError)
      end

      after :example do
        file.unlink
      end
    end
  end

  describe '#recognize_format' do
    context 'with ova image format' do
      let(:outputs) { load_outputs 'ova' }

      it 'recognizes image as OVA image' do
        outputs.each { |output| expect(Cloudkeeper::Managers::ImageManager.recognize_format(output)).to eq(:ova) }
      end
    end

    context 'with vmdk image format' do
      let(:outputs) { load_outputs 'vmdk' }

      it 'recognizes image as VMDK image' do
        outputs.each { |output| expect(Cloudkeeper::Managers::ImageManager.recognize_format(output)).to eq(:vmdk) }
      end
    end

    context 'with qcow2 image format' do
      let(:outputs) { load_outputs 'qcow2' }

      it 'recognizes image as QCOW2 image' do
        outputs.each { |output| expect(Cloudkeeper::Managers::ImageManager.recognize_format(output)).to eq(:qcow2) }
      end
    end

    context 'with raw image format' do
      let(:outputs) { load_outputs 'raw' }

      it 'recognizes image as RAW image' do
        outputs.each { |output| expect(Cloudkeeper::Managers::ImageManager.recognize_format(output)).to eq(:raw) }
      end
    end

    context 'with unknown image format' do
      let(:outputs) { load_outputs 'unknown' }

      it 'raise NoImageFormatRecognizedError exception' do
        outputs.each do |output|
          expect { Cloudkeeper::Managers::ImageManager.recognize_format(output) }.to \
            raise_error(Cloudkeeper::Errors::NoImageFormatRecognizedError)
        end
      end
    end
  end

  describe '#file_description' do
    let(:file) { 'file' }
    let(:command) { instance_double(Mixlib::ShellOut) }
    let(:output) { 'some dummy output' }

    before :example do
      expect(Mixlib::ShellOut).to receive(:new).with('file', '-b', file) { command }
      allow(command).to receive(:run_command)
      allow(command).to receive(:stdout) { output }
      allow(command).to receive(:command) { 'file -b file' }
      allow(command).to receive(:stderr) { 'some dummy error' }
    end

    context 'with sucessfull execution' do
      before :example do
        expect(command).to receive(:error?) { false }
      end

      it 'returns file description' do
        expect(Cloudkeeper::Managers::ImageManager.file_description(file)).to eq(output)
      end
    end

    context 'with failed execution' do
      before :example do
        expect(command).to receive(:error?) { true }
      end

      it 'raises CommandExecutionError exception' do
        expect { Cloudkeeper::Managers::ImageManager.file_description file }.to raise_error(Cloudkeeper::Errors::CommandExecutionError)
      end
    end
  end

  describe '#format' do
    let(:file) { File.join(MOCK_DIR, 'image_formats', 'ova') }
    let(:command) { instance_double(Mixlib::ShellOut) }
    let(:output) { 'POSIX tar archive (GNU)' }

    before :example do
      allow(Mixlib::ShellOut).to receive(:new).with('file', '-b', file) { command }
      allow(command).to receive(:run_command)
      allow(command).to receive(:stdout) { output }
      allow(command).to receive(:command) { 'file -b file' }
      allow(command).to receive(:stderr) { 'some dummy error' }
      allow(command).to receive(:error?) { false }
    end

    context 'if everything goes well' do
      it 'returns image format' do
        expect(Cloudkeeper::Managers::ImageManager.format(file)).to eq(:ova)
      end
    end

    context 'with failed command execution' do
      before :example do
        expect(command).to receive(:error?) { true }
      end

      it 'raises ImageFormatRecognitionError exception' do
        expect { Cloudkeeper::Managers::ImageManager.format file }.to raise_error(Cloudkeeper::Errors::ImageFormatRecognitionError)
      end
    end

    context 'with nonexisting file' do
      let(:file) { File.join('nonexisting', 'file') }

      it 'raises ImageFormatRecognitionError exception' do
        expect { Cloudkeeper::Managers::ImageManager.format file }.to raise_error(Cloudkeeper::Errors::ImageFormatRecognitionError)
      end
    end

    context 'with nonreadable file' do
      let(:file) do
        file = Tempfile.new('cloudkeeper-image')
        File.chmod(0o000, file.path)

        file
      end

      it 'raises ImageFormatRecognitionError exception' do
        expect { Cloudkeeper::Managers::ImageManager.format file }.to raise_error(Cloudkeeper::Errors::ImageFormatRecognitionError)
      end

      after :example do
        file.unlink
      end
    end

    context 'with nonexisting file' do
      let(:output) { 'unknown output' }

      it 'raises ImageFormatRecognitionError exception' do
        expect { Cloudkeeper::Managers::ImageManager.format file }.to raise_error(Cloudkeeper::Errors::ImageFormatRecognitionError)
      end
    end
  end
end

def load_outputs(file)
  File.readlines(File.join(MOCK_DIR, 'image_formats', file))
end
