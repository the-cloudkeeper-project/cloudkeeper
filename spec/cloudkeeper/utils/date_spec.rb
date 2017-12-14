require 'spec_helper'

describe Cloudkeeper::Utils::Date do
  describe '#parse' do
    context 'with nil date' do
      it 'returns empty string' do
        expect(described_class.parse(nil)).to eq('')
      end
    end

    context 'with empty date' do
      it 'returns empty string' do
        expect(described_class.parse('')).to eq('')
      end
    end

    context 'with real date' do
      it 'returns parsed Time instance' do
        expect(described_class.parse('2015-06-18T21:14:00Z')).to eq(Time.new(2015, 6, 18, 21, 14))
      end
    end
  end
end
