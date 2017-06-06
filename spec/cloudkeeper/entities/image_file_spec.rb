require 'spec_helper'

describe Cloudkeeper::Entities::ImageFile do
  subject(:image_file) { described_class.new '/some/file.raw', :raw, '123456', 555, true }

  describe '#new' do
    context 'not OVA image' do
      it 'returns ImageFile instance' do
        is_expected.to be_instance_of described_class
      end

      it 'returns ImageFile instance extended of Convertable module' do
        expect((class << image_file; self; end).included_modules).to include(Cloudkeeper::Entities::Convertables::Convertable)
      end
    end

    context 'OVA image' do
      subject(:image_file) { described_class.new '/some/file.ova', :ova, '123456', 666, true }

      it 'returns ImageFile instance' do
        is_expected.to be_instance_of described_class
      end

      it 'returns ImageFile instance extended of Convertable module' do
        expect((class << image_file; self; end).included_modules).to include(Cloudkeeper::Entities::Convertables::Convertable)
      end

      it 'returns ImageFile instance extended of OVA convertable module' do
        expect((class << image_file; self; end).included_modules).to include(Cloudkeeper::Entities::Convertables::Ova)
      end
    end
  end
end
