class Region < ApplicationRecord
  include GeometryConcern
  include MapHelper
  include SourceHelper

  has_many :countries
  has_many :protected_areas, through: :countries
  has_many :designations, -> { distinct }, through: :protected_areas
  has_many :iucn_categories, through: :protected_areas

  has_one :regional_statistic

  scope :without_global, -> { where.not(name: 'Global').order(:name) }

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

  def protected_areas_per_governance(exclude_oecms: false)
    ActiveRecord::Base.connection.execute("""
      SELECT governances.id AS governance_id, governances.name AS governance_name, governances.governance_type AS governance_type, pas_per_governances.count AS count, round((pas_per_governances.count::decimal/(SUM(pas_per_governances.count) OVER ())::decimal) * 100, 2) AS percentage
      FROM governances
      INNER JOIN (
        #{protected_areas_inner_join(:governance_id, exclude_oecms)}
      ) AS pas_per_governances
        ON pas_per_governances.governance_id = governances.id
      ORDER BY count DESC
    """)
  end

  def protected_areas_per_iucn_category
    region_data = {}
    processed_data = []
    total_region_count = []
    correct_order = ["Ia", "Ib", "II", "III", "IV", "V", "VI", "Not Reported", "Not Assigned", "Not Applicable"]

    countries.each do |country|
      country.protected_areas_per_iucn_category.each do |protected_area|
        region_pa_category = region_data[protected_area["iucn_category_name"]] ||= {}
        region_pa_category["count"] ||= 0
        region_pa_category["count"] += protected_area["count"].to_i
        total_region_count << protected_area["count"].to_i
      end
    end

    correct_order.each do |key,value|
      next if region_data[key].nil?
      processed_data << {
        "iucn_category_name" => key,
        "count" => region_data[key]["count"],
        "percentage" => 100 * region_data[key]["count"] / total_region_count.reduce(0, :+)
      }
    end

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
    # Do not include Global region in the search engine
    return if name == 'Global'

    self.as_json(
      only: [:id, :name, :iso]
    )
  end

  def extent_url
    region_extent_url(name)
  end

  def protected_areas_per_designation(jurisdiction=nil, exclude_oecms: false)
    ActiveRecord::Base.connection.execute("""
      SELECT designations.id AS designation_id, designations.name AS designation_name, pas_per_designations.count
      FROM designations
      INNER JOIN (
        #{protected_areas_inner_join(:designation_id, exclude_oecms)}
      ) AS pas_per_designations
        ON pas_per_designations.designation_id = designations.id
      #{"WHERE designations.jurisdiction_id = #{jurisdiction.id}" if jurisdiction}
    """)
  end

  def protected_areas_per_jurisdiction(exclude_oecms: false)
    ActiveRecord::Base.connection.execute("""
      SELECT jurisdictions.name, COUNT(*)
      FROM jurisdictions
      INNER JOIN designations ON jurisdictions.id = designations.jurisdiction_id
      INNER JOIN (
        SELECT protected_areas.designation_id
        FROM protected_areas
        INNER JOIN countries_protected_areas
          ON protected_areas.id = countries_protected_areas.protected_area_id
          AND countries_protected_areas.country_id IN (#{self.countries.pluck(:id).join(",")})
          #{"WHERE protected_areas.is_oecm = false" if exclude_oecms}
      ) AS pas_for_country ON pas_for_country.designation_id = designations.id
      GROUP BY jurisdictions.name
    """)
  end

  def countries_and_territories
    countries = self.countries
    all_countries_and_territories = []

    countries.each {|country| all_countries_and_territories << country.children }
    all_countries_and_territories << countries
    all_countries_and_territories.flatten.uniq
  end

  def sources_per_region
    sources = ActiveRecord::Base.connection.execute("""
      SELECT sources.title, EXTRACT(YEAR FROM sources.update_year) AS year, sources.responsible_party 
      FROM sources
      INNER JOIN countries_protected_areas
      ON countries_protected_areas.country_id IN (#{self.countries.pluck(:id).join(",")})
      INNER JOIN protected_areas_sources 
      ON protected_areas_sources.protected_area_id = countries_protected_areas.protected_area_id
      AND protected_areas_sources.source_id = sources.id
      """)
    convert_into_hash(sources.uniq)
  end

  private

  def protected_areas_inner_join(group_by, exclude_oecms)
    """
      SELECT #{group_by}, COUNT(protected_areas.id) AS count
      FROM protected_areas
      INNER JOIN countries_protected_areas
        ON protected_areas.id = countries_protected_areas.protected_area_id
        AND countries_protected_areas.country_id IN (#{self.countries.pluck(:id).join(",")})
        #{"WHERE protected_areas.is_oecm = false" if exclude_oecms}
      GROUP BY #{group_by}
    """
  end
end
