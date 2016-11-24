module Cloudkeeper
  module Errors
    module Parsing
      autoload :ParsingError, 'cloudkeeper/errors/parsing/parsing_error'
      autoload :InvalidApplianceHashError, 'cloudkeeper/errors/parsing/invalid_appliance_hash_error'
      autoload :InvalidImageHashError, 'cloudkeeper/errors/parsing/invalid_image_hash_error'
      autoload :InvalidImageListHashError, 'cloudkeeper/errors/parsing/invalid_image_list_hash_error'
    end
  end
end
