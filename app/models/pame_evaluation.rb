class PameEvaluation < ActiveRecord::Base
  belongs_to :protected_area

  validates :method, :year, :protected_area, presence: true
end
