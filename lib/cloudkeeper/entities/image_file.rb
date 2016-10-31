module Cloudkeeper
  module Entities
    class ImageFile < Struct.new(:file, :checksum, :format, :original)
    end
  end
end
