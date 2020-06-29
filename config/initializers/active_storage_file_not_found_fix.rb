# frozen_string_literal: true

# ActiveStorage raises an error 500 on File Not Found.
# To fix this, we will catch when it occurs and return a more FE-friendly
# response.
Rails.application.config.after_initialize do
  ::ActiveStorage::DiskController.class_eval do
    rescue_from Errno::ENOENT do
      head :not_found
    end
  end
  ::ActiveStorage::RepresentationsController.class_eval do
    rescue_from Errno::ENOENT do
      head :not_found
    end
  end
end
