class Country < ApplicationRecord
  include GeometryConcern
  include RelatableProtectedAreas

  include MapHelper
  include SourceHelper

  has_and_belongs_to_many :protected_areas

  has_one :country_statistic
  has_one :pame_statistic

  belongs_to :region
  belongs_to :region_for_index, -> { select('regions.id, regions.name') }, :class_name => 'Region', :foreign_key => 'region_id'

  has_many :sub_locations
  has_many :designations, -> { distinct }, through: :protected_areas
  has_many :iucn_categories, through: :protected_areas

  belongs_to :parent, class_name: "Country", foreign_key: :country_id
  has_many :children, class_name: "Country"

  has_and_belongs_to_many :pame_evaluations

  def wdpa_ids
    protected_areas.map(&:wdpa_id)
  end

  def statistic
    country_statistic
  end

  def assessments
    pame_evaluations.select{|pe| pe[:protected_area_id]}.count
  end

  def assessed_pas
    pame_evaluations.select{|pe| pe[:protected_area_id]}.map(&:wdpa_id).uniq.count
  end

  def protected_areas_with_iucn_categories
    valid_categories = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"
    chart_categories = iucn_categories.where(
      "iucn_categories.name IN (#{valid_categories})"
    )
  end

  def self.countries_with_gl
    joins(:protected_areas).where.not(protected_areas: {green_list_status_id: nil}).distinct
  end

  def total_gl_coverage
    protected_areas.green_list_areas.reduce(0) do |sum, x|
      sum + x.reported_area
    end
  end

  def self.data_providers
    joins(:protected_areas).uniq
  end

  def as_indexed_json options={}
    js = self.as_json(
      only: [:name, :iso_3, :id],
      include: {
        region_for_index: { only: [:name] }
      }
    )
    #crude remapping to flatten
    # TODO This line is now breaking the indexing. It looks like it's not require anymore
    #js['region_name'] = js['region_for_index']['name']
    js
  end

  def extent_url
    country_extent_url(iso_3)
  end

  def random_protected_areas wanted=1
    random_offset = rand(protected_areas.count-wanted)
    protected_areas.offset(random_offset).limit(wanted)
  end

  def sources_per_country(exclude_oecms: false)
    sources = ActiveRecord::Base.connection.execute("""
      SELECT sources.title, EXTRACT(YEAR FROM sources.update_year) AS year, sources.responsible_party 
      FROM sources
      INNER JOIN countries_protected_areas
      ON countries_protected_areas.country_id = #{self.id}
      INNER JOIN protected_areas_sources 
      ON protected_areas_sources.protected_area_id = countries_protected_areas.protected_area_id
      AND protected_areas_sources.source_id = sources.id

      #{"INNER JOIN protected_areas
      ON protected_areas_sources.protected_area_id = protected_areas.id
      WHERE protected_areas.is_oecm = false" if exclude_oecms}
      """)
    convert_into_hash(sources.uniq)
  end

  def protected_areas_per_designation(jurisdictions=[], exclude_oecms: false)
    ActiveRecord::Base.connection.execute("""
      SELECT designations.name AS designation_name, SUM(pas_per_designations.count) as count
      FROM designations
      INNER JOIN (
        #{protected_areas_inner_join(:designation_id, exclude_oecms)}
      ) AS pas_per_designations
        ON pas_per_designations.designation_id = designations.id
      #{"WHERE designations.jurisdiction_id IN (#{jurisdictions.pluck(:id).join(',')})" if jurisdictions.any?}
      GROUP BY designations.name
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
          AND countries_protected_areas.country_id = #{self.id}
        #{"WHERE protected_areas.is_oecm = false" if exclude_oecms}
      ) AS pas_for_country ON pas_for_country.designation_id = designations.id
      GROUP BY jurisdictions.name
    """)
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
          AND countries_protected_areas.country_id = #{self.id}
      ) AS pas_for_country ON pas_for_country.designation_id = designations.id
      INNER JOIN
        protected_areas_sources
      ON
        protected_areas_sources.protected_area_id = pas_for_country.id
      GROUP BY jurisdictions.name
    """)
  end

  def protected_areas_per_iucn_category(exclude_oecms: false)
    ActiveRecord::Base.connection.execute("""
      SELECT iucn_categories.id AS iucn_category_id, iucn_categories.name AS iucn_category_name, pas_per_iucn_categories.count, round((pas_per_iucn_categories.count::decimal/(SUM(pas_per_iucn_categories.count) OVER ())::decimal) * 100, 2) AS percentage
      FROM iucn_categories
      INNER JOIN (
        #{protected_areas_inner_join(:iucn_category_id, exclude_oecms)}
      ) AS pas_per_iucn_categories
        ON pas_per_iucn_categories.iucn_category_id = iucn_categories.id
    """)
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

  def coverage_growth(exclude_oecms)
    _year = 'EXTRACT(year from legal_status_updated_at)'
    ActiveRecord::Base.connection.execute(
      <<-SQL
        SELECT TO_TIMESTAMP(date_part::text, 'YYYY') AS year, SUM(count) OVER (ORDER BY date_part::INT) AS count
        FROM (#{protected_areas_inner_join(_year, exclude_oecms)}) t
        ORDER BY year
      SQL
    )
  end

  private

  def protected_areas_inner_join(group_by, exclude_oecms)
    """
      SELECT #{group_by}, COUNT(protected_areas.id) AS count 
      FROM protected_areas
      INNER JOIN countries_protected_areas
        ON protected_areas.id = countries_protected_areas.protected_area_id
        AND countries_protected_areas.country_id = #{self.id}
      #{"WHERE protected_areas.is_oecm = false" if exclude_oecms}
      GROUP BY #{group_by}
    """
  end
end
