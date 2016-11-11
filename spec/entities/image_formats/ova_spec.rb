describe Cloudkeeper::Entities::ImageFormats::Ova do
  subject(:ova_class) { Class.new { extend Cloudkeeper::Entities::ImageFormats::Ova } }

  describe '#ova?' do
    context 'with ova image file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'image.ova') }

      it 'returns true' do
        expect(ova_class.ova?(file)).to be_truthy
      end
    end

    context 'with fake ova image file - missing vmdk file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image01.ova') }

      it 'returns false' do
        expect(ova_class.ova?(file)).to be_falsy
      end
    end

    context 'with fake ova image file - missing ovf file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image02.ova') }

      it 'returns false' do
        expect(ova_class.ova?(file)).to be_falsy
      end
    end

    context 'with fake ova image file - missing both ovf and vmdk file' do
      let(:file) { File.join(MOCK_DIR, 'image_formats', 'fake-image03.ova') }

      it 'returns false' do
        expect(ova_class.ova?(file)).to be_falsy
      end
    end
  end
end
