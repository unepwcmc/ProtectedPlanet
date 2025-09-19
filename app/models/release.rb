# frozen_string_literal: true

class Release < ApplicationRecord
  has_many :release_events, dependent: :delete_all

  STATES = %w[started preflight_ok importing validating swapped rolled_back aborted failed succeeded].freeze

  validates :label, presence: true, uniqueness: true
  validates :state, inclusion: { in: STATES }
end

