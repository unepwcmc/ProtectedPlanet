# frozen_string_literal: true

module Staging
  class PameSource < ApplicationRecord
    self.table_name = 'staging_pame_sources'
    self.primary_key = 'id'

    has_many :pame_evaluations, class_name: 'Staging::PameEvaluation'
  end
end
