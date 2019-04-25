class PameEvaluation < ActiveRecord::Base
  belongs_to :protected_area
  belongs_to :pame_source
  has_and_belongs_to_many :countries

  validates :methodology, :year, :protected_area, :metadata_id, :url, presence: true
end
