module Staging
  class ProtectedAreaParcel < ApplicationRecord
    self.table_name = 'staging_protected_area_parcels'
    self.primary_key = 'id'

    # Make sure to make the uniqueness based on the conbination of wdpa_id + wdpa_pid
    validates :wdpa_id, uniqueness: { scope: :wdpa_pid }

    has_and_belongs_to_many :countries,
      # We still read countries from live countries table
      join_table: Country.staging_countries_pa_parcels_junction_table_name,
      foreign_key: 'protected_area_parcel_id',
      association_foreign_key: 'country_id'

    # As of 02Sep2025 we are not importing sub_locations to protected_area_parcels table
    # has_and_belongs_to_many :sub_locations

    has_and_belongs_to_many :sources,
      # we can use the name 'sources' everywhere but then it is linking from Staging::Source not Source table
      class_name: 'Staging::Source',
      join_table: Staging::Source.protected_area_parcels_sources_junction_table_name,
      foreign_key: 'protected_area_parcel_id',
      association_foreign_key: 'source_id'

    # As of 09Apr It seems networks are not used in the system now
    # has_many :networks_protected_areas
    # has_many :networks, through: :networks_protected_areas

    # We should only access pame_evaluations through protected_area
    # has_many :pame_evaluations
    # has_many :story_map_links

    belongs_to :protected_area, class_name: 'Staging::ProtectedArea', foreign_key: 'wdpa_id', primary_key: 'wdpa_id'
    belongs_to :legal_status
    belongs_to :iucn_category
    belongs_to :governance
    belongs_to :management_authority
    belongs_to :realm
    belongs_to :no_take_status, class_name: 'Staging::NoTakeStatus'
    belongs_to :designation
    delegate :jurisdiction, to: :designation, allow_nil: true

    after_create :create_slug

    def create_slug
      updated_slug = [wdpa_id, wdpa_pid, name, designation.try(:name)].join(' ').parameterize
      update_attributes(slug: updated_slug)
    end
  end
end
