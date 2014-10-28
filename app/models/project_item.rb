class ProjectItem < ActiveRecord::Base
  belongs_to :project
  belongs_to :item, polymorphic: true
end
