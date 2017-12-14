module Cloudkeeper
  module Utils
    class Date
      DATE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'.freeze

      def self.parse(date)
        date.blank? ? '' : Time.strptime(date, DATE_FORMAT)
      end
    end
  end
end
