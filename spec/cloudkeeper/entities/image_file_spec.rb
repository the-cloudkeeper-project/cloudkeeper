require 'spec_helper'

describe Cloudkeeper::Entities::ImageFile do
  subject(:image_file) { described_class.new '/some/file.raw', :raw, '123456', 555 }

  describe '#new' do
    context 'when not OVA image' do
      it 'returns ImageFile instance' do
        expect(image_file).to be_instance_of described_class
      end

      it 'returns ImageFile instance extended of Convertable module' do
        expect((class << image_file; self; end).included_modules).to include(Cloudkeeper::Entities::Convertables::Convertable)
      end
    end

    context 'when OVA image' do
      subject(:image_file) { described_class.new '/some/file.ova', :ova, '123456', 666 }

      it 'returns ImageFile instance' do
        expect(image_file).to be_instance_of described_class
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
