module Staging
  class ProtectedAreaParcel < ApplicationRecord
    self.table_name = 'staging_protected_area_parcels'
    self.primary_key = 'id'

    # Make sure to make the uniqueness based on the conbination of site_id + site_pid
    validates :site_id, uniqueness: { scope: :site_pid }

    has_and_belongs_to_many :countries,
      # We still read countries from live countries table
      join_table: Country.staging_countries_pa_parcels_junction_table_name,
      foreign_key: 'protected_area_parcel_id',
      association_foreign_key: 'country_id'

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

    belongs_to :protected_area, class_name: 'Staging::ProtectedArea', foreign_key: 'site_id', primary_key: 'site_id'
    belongs_to :legal_status
    belongs_to :iucn_category
    belongs_to :governance
    belongs_to :management_authority
    belongs_to :realm
    belongs_to :no_take_status, class_name: 'Staging::NoTakeStatus'
    belongs_to :designation
    delegate :jurisdiction, to: :designation, allow_nil: true

    after_create :create_slug
    before_save :set_legacy_fields

    def create_slug
      updated_slug = [site_id, site_pid, name, designation.try(:name)].join(' ').parameterize
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
