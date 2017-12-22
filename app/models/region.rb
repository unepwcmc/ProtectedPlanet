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

  def protected_areas_per_iucn_category
    region_data = Hash.new { |hash, key| hash[key] = Hash.new }
    processed_data = []
    total_region_count = []

    countries.each do |country|
      country.protected_areas_per_iucn_category.each do |protected_area|
        region_pa_category = region_data[protected_area["iucn_category_name"]]
        region_pa_category["count"] ||= 0
        region_pa_category["count"] += protected_area["count"].to_i
        total_region_count << protected_area["count"].to_i
        region_pa_category["percentage"] ||= 0
        region_pa_category["percentage"] += protected_area["percentage"].to_f
      end
    end

    processed_data = region_data.map{ |key,value| {
      "iucn_category_name" => key,
      "count" => value["count"],
      "percentage" => 100 * value["count"] / total_region_count.reduce(0, :+)
      }
    }

    processed_data
  end

  def sources_per_jurisdiction
    ActiveRecord::Base.connection.execute("""
      SELECT jurisdictions.name, COUNT(DISTINCT protected_areas_sources.source_id)
      FROM jurisdictions
      INNER JOIN designations ON jurisdictions.id = designations.jurisdiction_id
      INNER JOIN (
        SELECT protected_areas.id, protected_areas.designation_id
        FROM protected_areas
        INNER JOIN countries_protected_areas
          ON protected_areas.id = countries_protected_areas.protected_area_id
          AND countries_protected_areas.country_id IN (#{self.countries.pluck(:id).join(",")})
      ) AS pas_for_country ON pas_for_country.designation_id = designations.id
      INNER JOIN
        protected_areas_sources
      ON
        protected_areas_sources.protected_area_id = pas_for_country.id
      GROUP BY jurisdictions.name
    """)
  end

  def as_indexed_json options={}
    self.as_json(
      only: [:id, :name]
    )
  end

  def protected_areas_per_designation(jurisdiction=nil)
    ActiveRecord::Base.connection.execute("""
      SELECT designations.id AS designation_id, designations.name AS designation_name, pas_per_designations.count
      FROM designations
      INNER JOIN (
        #{protected_areas_inner_join(:designation_id)}
      ) AS pas_per_designations
        ON pas_per_designations.designation_id = designations.id
      #{"WHERE designations.jurisdiction_id = #{jurisdiction.id}" if jurisdiction}
    """)
  end

  def countries_and_territories
    countries = self.countries
    all_countries_and_territories = []

    countries.each {|country| all_countries_and_territories << country.children }
    all_countries_and_territories << countries
    all_countries_and_territories.flatten.uniq
  end

  private

  def protected_areas_inner_join group_by
    """
      SELECT #{group_by}, COUNT(protected_areas.id) AS count
      FROM protected_areas
      INNER JOIN countries_protected_areas
        ON protected_areas.id = countries_protected_areas.protected_area_id
        AND countries_protected_areas.country_id IN (#{self.countries.pluck(:id).join(",")})
      GROUP BY #{group_by}
    """
  end
end
