class Banner < ActiveRecord::Base
  validates :title,
    length: { maximum: 100 },
    allow_blank: true
  validates :content,
    presence: true,
    allow_nil: false

  scope :active, -> { where(is_active: true) }

  def self.current
    active.first
  end
end
