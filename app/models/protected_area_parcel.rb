# frozen_string_literal: true

# This file was copied from app/models/protected_area.rb then modified to only including/linking nedded columns
# As of 04Apr2025 sources and green_list_status are not linked up
# TODO: green_list_status needs linking up see lib/modules/wdpa/green_list_importer.rb for more info

class ProtectedAreaParcel < ApplicationRecord
  # Make sure to make the uniqueness based on the conbination of site_id + site_pid
  validates :site_id, uniqueness: { scope: :site_pid }

  has_and_belongs_to_many :countries
  has_and_belongs_to_many :sources

  # As of 09Apr It seems networks are not used in the system now
  # has_many :networks_protected_areas
  # has_many :networks, through: :networks_protected_areas

  # We should only access pame_evaluations through protected_area
  # has_many :pame_evaluations
  # has_many :story_map_links

  belongs_to :protected_area, foreign_key: 'site_id', primary_key: 'site_id'
  belongs_to :legal_status
  belongs_to :iucn_category
  belongs_to :governance
  belongs_to :management_authority
  belongs_to :realm
  belongs_to :no_take_status
  belongs_to :designation
  delegate :jurisdiction, to: :designation, allow_nil: true

  # As of 09Apr2025 we are not clear if there is possibility to only green list certain parcels in a PA
  # belongs_to :green_list_status

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
