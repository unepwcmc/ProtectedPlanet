class PameEvaluation < ActiveRecord::Base
  belongs_to :protected_area

  validates :methodology, :year, :protected_area, presence: true
end
