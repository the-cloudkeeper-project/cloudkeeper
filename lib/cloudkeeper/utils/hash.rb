module Cloudkeeper
  module Utils
    class Hash
      def self.values?(hash_instance, *keys)
        keys.reduce(true) { |acc, elem| !hash_instance[elem].blank? && acc }
      end
    end
  end
end
