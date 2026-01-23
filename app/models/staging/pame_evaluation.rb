# frozen_string_literal: true

module Staging
  class PameEvaluation < ApplicationRecord
    self.table_name = 'staging_pame_evaluations'
    self.primary_key = 'id'

    belongs_to :protected_area, class_name: 'Staging::ProtectedArea', optional: true
    belongs_to :protected_area_parcel, class_name: 'Staging::ProtectedAreaParcel', optional: true
    belongs_to :pame_source, class_name: 'Staging::PameSource'
    belongs_to :pame_method, optional: true
    has_and_belongs_to_many :countries,
      join_table: Country.staging_countries_pame_evaluations_junction_table_name,
      foreign_key: 'pame_evaluation_id',
      association_foreign_key: 'country_id'

    validates :method, :asmt_year, :asmt_id, presence: true
  end
end
