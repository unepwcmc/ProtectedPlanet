module Staging
  class StoryMapLink < ApplicationRecord
    self.table_name = 'staging_story_map_links'
    belongs_to :protected_area, class_name: 'Staging::ProtectedArea'
  end
end
