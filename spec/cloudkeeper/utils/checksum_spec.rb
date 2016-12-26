require 'spec_helper'

describe Cloudkeeper::Utils::Checksum do
  describe '#compute' do
    let(:file) { File.join(MOCK_DIR, 'image_conversions', 'image.raw') }

    it 'computes SHA512 checksum for file' do
      expect(described_class.compute(file)).to eq('0d8ce85be8cce1bba62db93e01c882f4ffb5a13141e255919e5048c7f7ad08bb204bd5d176c7' \
                                                  '8dbada068476fcf5da8ee4963feee14e20fe82bc8efb14d7211f')
    end
  end
end
