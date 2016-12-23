require 'spec_helper'

describe Cloudkeeper::Entities::Image do
  subject(:image) { described_class.new 'http://image.uri', '123456789' }

  describe '#new' do
    it 'returns instance of Image' do
      is_expected.to be_instance_of described_class
    end

    it 'without setting prepares image_files attribute as an array instance' do
      expect(image.image_files).to be_instance_of Array
    end

    it 'without setting prepares image_files attribute as empty array' do
      expect(image.image_files).to be_empty
    end

    it 'without setting prepares size as 0' do
      expect(image.size).to eq(0)
    end

    context 'with nil uri' do
      it 'raises ArgumentError exception' do
        expect { described_class.new nil, '123456789' }.to raise_error(Cloudkeeper::Errors::ArgumentError)
      end
    end

    context 'with nil checksum' do
      it 'raises ArgumentError exception' do
        expect { described_class.new 'http://image.uri', nil }.to raise_error(Cloudkeeper::Errors::ArgumentError)
      end
    end
  end

  describe '.add_image_file' do
    context 'with nil image file' do
      it 'raises ArgumentError exception' do
        expect { image.add_image_file nil }.to raise_error(Cloudkeeper::Errors::ArgumentError)
      end
    end

    context 'with proper image file' do
      let(:image_file) { instance_double(Cloudkeeper::Entities::ImageFile) }
      it 'adds image file into its array' do
        image.add_image_file image_file
        expect(image.image_files.count).to eq(1)
        expect(image.image_files.first).to eq(image_file)
      end
    end
  end

  describe '#from_hash' do
    context 'with hash with correct values' do
      let(:hash) do
        {
          'hv:size' => 42,
          'hv:uri' => 'http://some.uri.net/some/path',
          'sl:checksum:sha512' => '81a106e4f352b2ff21c691280d9bfd3dfafdbe07154f414ae563d1786ff55a254e66e94e6644ae1f175'\
                                  '70a502cd46d3e7f2ece043fcd211818eed871f4aaef53'
        }
      end

      it 'populates and returns Image instance' do
        image_instance = described_class.from_hash hash

        expect(image_instance.size).to eq(42)
        expect(image_instance.uri).to eq('http://some.uri.net/some/path')
        expect(image_instance.checksum).to eq('81a106e4f352b2ff21c691280d9bfd3dfafdbe07154f414ae563d1786ff55a254e66e94e6644ae1f175'\
                                              '70a502cd46d3e7f2ece043fcd211818eed871f4aaef53')
      end
    end

    context 'with hash with missing optional values' do
      let(:hash) do
        {
          'hv:uri' => 'http://some.uri.net/some/path',
          'sl:checksum:sha512' => '81a106e4f352b2ff21c691280d9bfd3dfafdbe07154f414ae563d1786ff55a254e66e94e6644ae1f175'\
                                  '70a502cd46d3e7f2ece043fcd211818eed871f4aaef53'
        }
      end

      it 'populates and returns Image instance with missing values as nils' do
        image_instance = described_class.from_hash hash

        expect(image_instance.size).to be_nil
        expect(image_instance.uri).to eq('http://some.uri.net/some/path')
        expect(image_instance.checksum).to eq('81a106e4f352b2ff21c691280d9bfd3dfafdbe07154f414ae563d1786ff55a254e66e94e6644ae1f175'\
                                              '70a502cd46d3e7f2ece043fcd211818eed871f4aaef53')
      end
    end

    context 'with hash with missing mandatory values' do
      let(:hash) do
        {
          'hv:size' => 42,
          'sl:checksum:sha512' => '81a106e4f352b2ff21c691280d9bfd3dfafdbe07154f414ae563d1786ff55a254e66e94e6644ae1f175'\
                                  '70a502cd46d3e7f2ece043fcd211818eed871f4aaef53'
        }
      end

      it 'fails with an InvalidImageHashError exception' do
        expect { described_class.from_hash hash }.to raise_error ::Cloudkeeper::Errors::Parsing::InvalidImageHashError
      end
    end

    context 'with empty hash' do
      let(:hash) { {} }

      it 'fails with an InvalidImageHashError exception' do
        expect { described_class.from_hash hash }.to raise_error ::Cloudkeeper::Errors::Parsing::InvalidImageHashError
      end
    end

    context 'with nil hash' do
      let(:hash) { nil }

      it 'fails with an InvalidImageHashError exception' do
        expect { described_class.from_hash hash }.to raise_error ::Cloudkeeper::Errors::Parsing::InvalidImageHashError
      end
    end

    context 'with hash with redundant values' do
      let(:hash) do
        {
          'hv:size' => 42,
          'hv:uri' => 'http://some.uri.net/some/path',
          'sl:checksum:sha512' => '81a106e4f352b2ff21c691280d9bfd3dfafdbe07154f414ae563d1786ff55a254e66e94e6644ae1f175'\
                                  '70a502cd46d3e7f2ece043fcd211818eed871f4aaef53',
          'redundant_key' => 'redundant_value'
        }
      end

      it 'populates and returns Image instance ignoring redundant values' do
        image_instance = described_class.from_hash hash

        expect(image_instance.size).to eq(42)
        expect(image_instance.uri).to eq('http://some.uri.net/some/path')
        expect(image_instance.checksum).to eq('81a106e4f352b2ff21c691280d9bfd3dfafdbe07154f414ae563d1786ff55a254e66e94e6644ae1f175'\
                                              '70a502cd46d3e7f2ece043fcd211818eed871f4aaef53')
      end
    end
  end

  describe '.available_formats' do
    let(:image_files) do
      [
        Struct.new(:format).new(:qcow),
        Struct.new(:format).new(:vmdk),
        Struct.new(:format).new(:raw)
      ]
    end
    let(:formats) { [:qcow, :raw, :vmdk] }

    before do
      image.image_files = image_files
    end

    it 'returns list of available image formats sorted alphabetically' do
      expect(image.available_formats).to eq(formats)
    end

    context 'with no image files' do
      before do
        image.image_files = []
      end

      it 'returns an empty array' do
        expect(image.available_formats).to be_empty
      end
    end
  end

  describe '.image_file' do
    let(:selected_image_file) { Struct.new(:format).new(:vmdk) }
    let(:image_files) do
      [
        Struct.new(:format).new(:qcow),
        selected_image_file,
        Struct.new(:format).new(:raw)
      ]
    end
    let(:formats) { [:qcow, :raw, :vmdk] }

    before do
      image.image_files = image_files
    end

    it 'returns image file with specified format' do
      expect(image.image_file(:vmdk)).to eq(selected_image_file)
    end

    context 'if such a format is not available' do
      it 'returns nil' do
        expect(image.image_file(:non_existing_format)).to be_nil
      end
    end
  end
end
