class Country < ActiveRecord::Base
  include GeometryConcern

  has_and_belongs_to_many :protected_areas

  has_one :country_statistic

  belongs_to :region
  belongs_to :region_for_index, -> { select("regions.id, regions.name") }, :class_name => "Region", :foreign_key => "region_id"

  has_many :sub_locations
  has_many :designations, -> { uniq }, through: :protected_areas
  has_many :iucn_categories, through: :protected_areas

  def statistic
    country_statistic
  end

  def protected_areas_with_iucn_categories
    valid_categories = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"
    iucn_categories.where(
      "iucn_categories.name IN (#{valid_categories})"
    )
  end

  def self.data_providers
    joins(:protected_areas).uniq
  end

  def as_indexed_json options={}
    self.as_json(
      only: [:id, :name],
      include: {
        region_for_index: { only: [:id, :name] }
      }
    )
  end
end
