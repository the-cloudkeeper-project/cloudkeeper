require 'spec_helper'

describe Cloudkeeper::Entities::Image do
  subject(:image) { Cloudkeeper::Entities::Image.new }

  IMAGE_ATTRS = [:image_files, :size, :uri, :checksum].freeze

  IMAGE_ATTRS.each do |attr|
    it "has #{attr} accessor" do
      is_expected.to have_attr_accessor attr.to_sym
    end
  end

  describe '#new' do
    it 'returns instance of Image' do
      is_expected.to be_instance_of Cloudkeeper::Entities::Image
    end

    it 'prepares image_files attribute as an empty array' do
      expect(image.image_files).to be_instance_of Array
      expect(image.image_files).to be_empty
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
        image_instance = Cloudkeeper::Entities::Image.from_hash hash

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
        image_instance = Cloudkeeper::Entities::Image.from_hash hash

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
        expect { Cloudkeeper::Entities::Image.from_hash hash }.to raise_error ::Cloudkeeper::Errors::InvalidImageHashError
      end
    end

    context 'with empty hash' do
      let(:hash) { {} }

      it 'fails with an InvalidImageHashError exception' do
        expect { Cloudkeeper::Entities::Image.from_hash hash }.to raise_error ::Cloudkeeper::Errors::InvalidImageHashError
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
        image_instance = Cloudkeeper::Entities::Image.from_hash hash

        expect(image_instance.size).to eq(42)
        expect(image_instance.uri).to eq('http://some.uri.net/some/path')
        expect(image_instance.checksum).to eq('81a106e4f352b2ff21c691280d9bfd3dfafdbe07154f414ae563d1786ff55a254e66e94e6644ae1f175'\
                                              '70a502cd46d3e7f2ece043fcd211818eed871f4aaef53')
      end
    end
  end
end
