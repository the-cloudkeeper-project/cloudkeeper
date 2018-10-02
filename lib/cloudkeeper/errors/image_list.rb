module Cloudkeeper
  module Errors
    module ImageList
      autoload :ImageListError, 'cloudkeeper/errors/image_list/image_list_error'
      autoload :VerificationError, 'cloudkeeper/errors/image_list/verification_error'
      autoload :RetrievalError, 'cloudkeeper/errors/image_list/retrieval_error'
      autoload :DownloadError, 'cloudkeeper/errors/image_list/download_error'
    end
  end
end
