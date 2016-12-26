module Cloudkeeper
  module Utils
    class Checksum
      def self.compute(file)
        Digest::SHA512.file(file).hexdigest
      end
    end
  end
end
