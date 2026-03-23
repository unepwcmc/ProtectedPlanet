# frozen_string_literal: true

class PameMethod < ApplicationRecord
  has_many :pame_evaluations

  validates :name, presence: true, uniqueness: true
end
