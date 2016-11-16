require 'spec_helper'

describe Cloudkeeper::Utils::Hash do
  describe '#values?' do
    let(:hash) { load_file('hash01.json') }

    context 'with all values available and not blank' do
      it 'returns true' do
        expect(described_class.values?(hash, 'name', 'gender', 'company')).to be_truthy
      end
    end

    context 'with some values available but empty' do
      let(:hash) { load_file('hash02.json') }

      it 'returns false' do
        expect(described_class.values?(hash, 'name', 'gender', 'company')).to be_falsy
      end
    end

    context 'with some values unavailable' do
      let(:hash) { load_file('hash03.json') }

      it 'returns false' do
        expect(described_class.values?(hash, 'name', 'picture', 'age')).to be_falsy
      end
    end
  end
end
