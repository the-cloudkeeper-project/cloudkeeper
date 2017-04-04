module Cloudkeeper
  module Utils
    class URL
      URL_REGEXP = /\A#{URI.regexp(%w[http https])}\z/

      def self.check!(url)
        raise Cloudkeeper::Errors::InvalidURLError, "#{url.inspect} is not a valid URL" unless url =~ URL_REGEXP
      end
    end
  end
end
