require 'zaru'

module Cloudkeeper
  module Utils
    class Filename
      WHITESPACES_REGEXP = /\s+/

      def self.sanitize(name)
        Zaru.sanitize!(name).gsub(WHITESPACES_REGEXP, '_')
      end
    end
  end
end
