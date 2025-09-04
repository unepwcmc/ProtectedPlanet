# frozen_string_literal: true

module Staging
  class PameEvaluation < ApplicationRecord
    self.table_name = 'staging_pame_evaluations'

    belongs_to :protected_area, class_name: 'Staging::ProtectedArea', optional: true
    belongs_to :pame_source, class_name: 'Staging::PameSource'
    has_and_belongs_to_many :countries,
      join_table: Country.staging_countries_pame_evaluations_junction_table_name,
      foreign_key: 'pame_evaluation_id',
      association_foreign_key: 'country_id'

    validates :methodology, :year, :metadata_id, presence: true
  end
end
