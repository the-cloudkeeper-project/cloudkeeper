require 'http'

module CloudKeeper
  class ImageListManager
    attr_reader :image_list

    def initialize
      @image_list = []
    end

    def download_image_lists
    end

    private

    def convert_image_list(file)
    end

    def verify_image_list(file)
    end
  end
end
