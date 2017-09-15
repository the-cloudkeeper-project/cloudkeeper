require 'spec_helper'

describe Cloudkeeper::Utils::Hash do
  describe '#values?' do
    let(:hash) { load_file('hash01.json') }

    context 'with all values available and not blank' do
      it 'returns true' do
        expect(described_class).to be_values(hash, 'name', 'gender', 'company')
      end
    end

    context 'with some values available but empty' do
      let(:hash) { load_file('hash02.json') }

      it 'returns false' do
        expect(described_class).not_to be_values(hash, 'name', 'gender', 'company')
      end
    end

    context 'with some values unavailable' do
      let(:hash) { load_file('hash03.json') }

      it 'returns false' do
        expect(described_class).not_to be_values(hash, 'name', 'picture', 'age')
      end
    end
  end
end
