class HomeCarouselSlide < ActiveRecord::Base
  validates :title,
    presence: true,
    length: {maximum: 30},
    allow_nil: false
  validates :description,
    presence: true,
    length: {maximum: 150},
    allow_nil: false
  validates :url,
    presence: true,
    length: {maximum: 255},
    allow_nil: false
end