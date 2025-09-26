module Staging
  class ProtectedArea < ApplicationRecord
    include GeometryConcern
    include SourceHelper

    self.table_name = 'staging_protected_areas'
    self.primary_key = 'id'

    has_and_belongs_to_many :countries,
      # We still read countries from live countries table not like sources below
      join_table: Country.staging_countries_pas_junction_table_name,
      foreign_key: 'protected_area_id',
      association_foreign_key: 'country_id'

    has_and_belongs_to_many :sources,
      # we can use the name 'sources' everywhere but then it is linking from Staging::Source not Source table
      class_name: 'Staging::Source',
      join_table: Staging::Source.protected_areas_sources_junction_table_name,
      foreign_key: 'protected_area_id',
      association_foreign_key: 'source_id'

    # As of 02Sep2025 we are not importing sub_locations to protected_areas table
    # has_and_belongs_to_many :sub_locations

    has_many :protected_area_parcels,
      # we can use the name 'protected_area_parcels' everywhere but then it is linking to Staging::ProtectedAreaParcel not ProtectedAreaParcel (live) table
      class_name: 'Staging::ProtectedAreaParcel',
      foreign_key: 'site_id',
      primary_key: 'site_id',
      dependent: :destroy

    has_many :networks_protected_areas, dependent: :destroy
    has_many :networks, through: :networks_protected_areas
    has_many :pame_evaluations, class_name: 'Staging::PameEvaluation'
    has_many :story_map_links, class_name: 'Staging::StoryMapLink'

    belongs_to :no_take_status, class_name: 'Staging::NoTakeStatus'
    belongs_to :legal_status
    belongs_to :iucn_category
    belongs_to :governance
    belongs_to :management_authority
    belongs_to :realm

    belongs_to :designation
    delegate :jurisdiction, to: :designation, allow_nil: true
    belongs_to :green_list_status, class_name: 'Staging::GreenListStatus'

    after_create :create_slug
    before_save :set_legacy_fields

    def create_slug
      updated_slug = [site_id, name, designation.try(:name)].join(' ').parameterize
      update_attributes(slug: updated_slug)
    end

    private

    # To be removed after migration - ensures wdpa_id and wdpa_pid are filled for backward compatibility
    def set_legacy_fields
      self.wdpa_id = site_id if site_id.present?
      self.wdpa_pid = site_pid if site_pid.present?
    end
  end
end
