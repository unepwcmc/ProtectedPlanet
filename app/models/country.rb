class Country < ActiveRecord::Base
  include GeometryConcern

  has_one :country_statistic

  belongs_to :region

  has_many :sub_locations
  has_many :designations, -> { uniq }, through: :protected_areas
  has_many :iucn_categories, through: :protected_areas

  has_and_belongs_to_many :protected_areas

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
end
