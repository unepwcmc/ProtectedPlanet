# frozen_string_literal: true

class ReleaseEvent < ApplicationRecord
  belongs_to :release

  validates :phase, presence: true
  validates :at, presence: true
end

