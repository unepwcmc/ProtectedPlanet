class StoryMapLink < ActiveRecord::Base
  belongs_to :protected_area, primary_key: :wdpa_id, foreign_key: :wdpa_id
end
