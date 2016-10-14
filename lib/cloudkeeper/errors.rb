module Cloudkeeper
  module Errors
    autoload :StandardError, 'cloudkeeper/errors/standard_error'
    autoload :ArgumentError, 'cloudkeeper/errors/argument_error'
    autoload :ImageListVerificationError, 'cloudkeeper/errors/image_list_verification_error'
    autoload :InvalidImageHashError, 'cloudkeeper/errors/invalid_image_hash_error'
    autoload :InvalidApplianceHashError, 'cloudkeeper/errors/invalid_appliance_hash_error'
    autoload :InvalidURLError, 'cloudkeeper/errors/invalid_url_error'
  end
end
