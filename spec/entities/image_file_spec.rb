require 'spec_helper'

describe Cloudkeeper::Entities::ImageFile do
  subject(:image_file) { Cloudkeeper::Entities::ImageFile.new }

  IMAGE_FILE_ATTRS = [:file, :original, :format, :checksum].freeze

  IMAGE_FILE_ATTRS.each do |attr|
    it "has #{attr} accessor" do
      is_expected.to have_attr_accessor attr.to_sym
    end
  end
end
