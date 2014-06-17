class Image < ActiveRecord::Base
  def self.for_bounds bounds
    image_attributes = Panoramio.images_for_bounds bounds

    image_attributes.map do |image|
      create image
    end
  end
end
