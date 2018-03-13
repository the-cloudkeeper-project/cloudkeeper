require 'spec_helper'

describe Cloudkeeper::Utils::Filename do
  describe '#sanitize' do
    let(:filenames) do
      [
        'xxx',
        '  xxx',
        'xxx  ',
        '   xxx   ',
        'x/x/x',
        'x./*xx',
        'xx   xx'
      ]
    end

    let(:sanitized) do
      [
        'xxx',
        'xxx',
        'xxx',
        'xxx',
        'xxx',
        'x.xx',
        'xx_xx'
      ]
    end

    it 'sanitizes a filename' do
      filenames.each_with_index { |filename, index| expect(described_class.sanitize(filename)).to eq(sanitized[index]) }
    end
  end
end
