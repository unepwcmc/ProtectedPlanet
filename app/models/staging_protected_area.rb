class StagingProtectedArea < ApplicationRecord
  include GeometryConcern
  include SourceHelper

  self.table_name = "staging_protected_areas"

  has_and_belongs_to_many :countries,
                          # We still read countries from live countries table not like sources below 
                          join_table: 'staging_countries_protected_areas',
                          foreign_key: 'protected_area_id',
                          association_foreign_key: 'country_id'
                          
  has_and_belongs_to_many :sources, 
                          # we can use the name 'sources' everywhere but then it is linking from StagingSource not Source table
                          class_name: 'StagingSource',
                          join_table: 'staging_protected_areas_sources',
                          foreign_key: 'protected_area_id',
                          association_foreign_key: 'source_id'

  has_many :protected_area_parcels, 
            # we can use the name 'protected_area_parcels' everywhere but then it is linking to StagingProtectedAreaParcel not ProtectedAreaParcel (live) table
            class_name: 'StagingProtectedAreaParcel',
            foreign_key: 'wdpa_id',
            primary_key: 'wdpa_id',
            dependent: :destroy

  has_many :networks_protected_areas, dependent: :destroy
  has_many :networks, through: :networks_protected_areas
  has_many :pame_evaluations
  has_many :story_map_links

  belongs_to :legal_status
  belongs_to :iucn_category
  belongs_to :governance
  belongs_to :management_authority
  belongs_to :no_take_status
  belongs_to :designation
  delegate :jurisdiction, to: :designation, allow_nil: true
  belongs_to :green_list_status

  after_create :create_slug

  def create_slug
    updated_slug = [wdpa_id, name, designation.try(:name)].join(' ').parameterize
    update_attributes(slug: updated_slug)
  end
end
