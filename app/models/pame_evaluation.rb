class PameEvaluation < ActiveRecord::Base
  belongs_to :protected_area
  belongs_to :pame_source

  validates :methodology, :year, :protected_area, :metadata_id, :url, presence: true
end
