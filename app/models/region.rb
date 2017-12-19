class Region < ActiveRecord::Base
  include GeometryConcern

  has_many :countries
  has_many :protected_areas, through: :countries
  has_many :designations, -> { uniq }, through: :protected_areas
  has_many :iucn_categories, through: :protected_areas

  has_one :regional_statistic

  def wdpa_ids
    protected_areas.map(&:wdpa_id)
  end

  def statistic
    regional_statistic
  end

  def countries_providing_data
    countries.joins(:protected_areas).uniq
  end

  def protected_areas_with_iucn_categories
    valid_categories = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"
    iucn_categories.where(
      "iucn_categories.name IN (#{valid_categories})"
    )
  end

  def protected_areas_per_governance
    region_data = Hash.new { |hash, key| hash[key] = Hash.new }
    processed_data = []
    total_region_count = []

    countries.each do |country|
      country.protected_areas_per_governance.each do |protected_area|
        region_pa_category = region_data[protected_area["governance_name"]]
        region_pa_category["governance_type"] ||= protected_area["governance_type"]
        region_pa_category["count"] ||= 0
        region_pa_category["count"] += protected_area["count"].to_i
        total_region_count << protected_area["count"].to_i
        region_pa_category["percentage"] ||= 0
        region_pa_category["percentage"] += protected_area["percentage"].to_f
      end
    end

    processed_data = region_data.map{ |key,value| {
          "governance_name" => key,
          "governance_type" => value["governance_type"],
          "count" => value["count"],
          "percentage" => 100 * value["count"] / total_region_count.reduce(0, :+)
        }
    }
  end

  def as_indexed_json options={}
    self.as_json(
      only: [:id, :name]
    )
  end
end
