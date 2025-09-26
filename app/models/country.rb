class Country < ApplicationRecord
  include GeometryConcern
  include RelatableProtectedAreas

  include MapHelper
  include SourceHelper

  def self.countries_pas_junction_table_name
    'countries_protected_areas'
  end

  def self.countries_pa_parcels_junction_table_name
    'countries_protected_area_parcels'
  end

  def self.countries_pame_evaluations_junction_table_name
    'countries_pame_evaluations'
  end

  def self.staging_countries_pas_junction_table_name
    'staging_countries_protected_areas'
  end

  def self.staging_countries_pa_parcels_junction_table_name
    'staging_countries_protected_area_parcels'
  end

  def self.staging_countries_pame_evaluations_junction_table_name
    'staging_countries_pame_evaluations'
  end

  has_and_belongs_to_many :protected_areas
  has_and_belongs_to_many :protected_area_parcels

  has_one :country_statistic
  has_one :pame_statistic

  belongs_to :region
  belongs_to :region_for_index, lambda {
                                  select('regions.id, regions.name')
                                }, class_name: 'Region', foreign_key: 'region_id'

  has_many :sub_locations
  has_many :designations, -> { distinct }, through: :protected_areas
  has_many :iucn_categories, through: :protected_areas

  belongs_to :parent, class_name: 'Country', foreign_key: :country_id
  has_many :children, class_name: 'Country'

  has_and_belongs_to_many :pame_evaluations
  has_and_belongs_to_many :staging_pame_evaluations,
    class_name: 'Staging::PameEvaluation',
    join_table: staging_countries_pame_evaluations_junction_table_name,
    foreign_key: 'country_id',
    association_foreign_key: 'pame_evaluation_id'

  BLACKLISTED_ISO3 = ['IOT'].freeze # Add countries in this list which we dont to show anywhere

  default_scope { where.not(iso_3: BLACKLISTED_ISO3) }

  def site_ids
    protected_areas.map(&:site_id)
  end

  def statistic
    country_statistic
  end

  def assessments
    # If you change here then also change def staging_assessments below for importer to run correctly
    # join protected_area table to exclude PAME evaluations where site_id doesn't exist anymore or the site is restricted
    # count PAME evaluations of protected areas within the given country - excluding overseas territories
    return pame_evaluations.joins(protected_area: :countries).where(countries: { id: id }).count if country_id.nil?

    # protected areas located in the overseas territories have PAME evaluations reported by their parent country
    # look up the parent country and count PAME evaluations for the given overseas territory
    parent&.pame_evaluations&.joins(protected_area: :countries)&.where(countries: { id: id })&.count
  end

  def assessed_pas
    # If you change here then also change def staging_assessed_pas below for importer to run correctly

    # join protected_area table to exclude PAME evaluations where site_id doesn't exist anymore or the site is restricted
    # count protected areas with PAME evaluations within the given country - excluding overseas territories
    if country_id.nil?
      return pame_evaluations.joins(protected_area: :countries).where(countries: { id: id })&.pluck(:protected_area_id)&.uniq&.count
    end

    # protected areas located in the overseas territories have PAME evaluations reported by their parent country
    # look up the parent country and count protected areas with PAME evaluations for the given overseas territory
    parent&.pame_evaluations&.joins(protected_area: :countries)&.where(countries: { id: id })&.pluck(:protected_area_id)&.uniq&.count
  end

  # Staging versions that work with staging PAME evaluations and protected areas
  def staging_assessments
    # If you change here then also change def assessments above for live table to query correctly
    # count staging PAME evaluations of staging protected areas within the given country - excluding overseas territories
    if country_id.nil?
      return staging_pame_evaluations.joins(protected_area: :countries).where(countries: { id: id }).count
    end

    # protected areas located in the overseas territories have PAME evaluations reported by their parent country
    # look up the parent country and count staging PAME evaluations for the given overseas territory
    parent&.staging_pame_evaluations&.joins(protected_area: :countries)&.where(countries: { id: id })&.count
  end

  def staging_assessed_pas
    # If you change here then also change def assessed_pas above for live table to query correctly

    # count staging protected areas with staging PAME evaluations within the given country - excluding overseas territories
    if country_id.nil?
      return staging_pame_evaluations.joins(protected_area: :countries).where(countries: { id: id })&.pluck(:protected_area_id)&.uniq&.count
    end

    # protected areas located in the overseas territories have PAME evaluations reported by their parent country
    # look up the parent country and count staging protected areas with staging PAME evaluations for the given overseas territory
    parent&.staging_pame_evaluations&.joins(protected_area: :countries)&.where(countries: { id: id })&.pluck(:protected_area_id)&.uniq&.count
  end

  def protected_areas_with_iucn_categories
    valid_categories = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"
    chart_categories = iucn_categories.where(
      "iucn_categories.name IN (#{valid_categories})"
    )
  end

  def self.countries_with_gl
    joins(:protected_areas).where.not(protected_areas: { green_list_status_id: nil }).distinct
  end

  def total_gl_coverage
    protected_areas.green_list_areas.reduce(0) do |sum, x|
      sum + x.reported_area
    end
  end

  def self.data_providers
    joins(:protected_areas).uniq
  end

  def as_indexed_json(_options = {})
    as_json(
      only: %i[name iso_3 id],
      include: {
        region_for_index: { only: [:name] }
      }
    )
    # crude remapping to flatten
    # TODO This line is now breaking the indexing. It looks like it's not require anymore
    # js['region_name'] = js['region_for_index']['name']
  end

  def extent_url
    # To account for incorporation of IOT into MUS, which is not reflected in the WDPA
    # data yet. This is a temporary fix until the WDPA data is updated.
    # TO DO: Remove this conditional once the WDPA data is updated.
    iso_3_value = iso_3 == 'IOT' ? 'MUS' : iso_3
    country_extent_url(iso_3_value)
  end

  def random_protected_areas(wanted = 1)
    random_offset = rand(protected_areas.count - wanted)
    protected_areas.offset(random_offset).limit(wanted)
  end

  def sources_per_country(exclude_oecms: false)
    sources = ActiveRecord::Base.connection.execute("
      SELECT sources.title, EXTRACT(YEAR FROM sources.update_year) AS year, sources.responsible_party
      FROM sources
      INNER JOIN countries_protected_areas
      ON countries_protected_areas.country_id = #{id}
      INNER JOIN protected_areas_sources
      ON protected_areas_sources.protected_area_id = countries_protected_areas.protected_area_id
      AND protected_areas_sources.source_id = sources.id

      #{if exclude_oecms
          "INNER JOIN protected_areas
      ON protected_areas_sources.protected_area_id = protected_areas.id
      WHERE protected_areas.is_oecm = false"
        end}
      ")
    convert_into_hash(sources.uniq)
  end

  def protected_areas_per_designation(jurisdictions = [], exclude_oecms: false)
    ActiveRecord::Base.connection.execute("
      SELECT designations.name AS designation_name, SUM(pas_per_designations.count) as count
      FROM designations
      INNER JOIN (
        #{protected_areas_inner_join(:designation_id, exclude_oecms)}
      ) AS pas_per_designations
        ON pas_per_designations.designation_id = designations.id
      #{"WHERE designations.jurisdiction_id IN (#{jurisdictions.pluck(:id).join(',')})" if jurisdictions.any?}
      GROUP BY designations.name
    ")
  end

  def designations_list_by_wdpa_or_oecm(jurisdictions: [], only_unique_site_ids: false, is_oecm: false)
    # If you need to have more fields in select feel free to add.
    # Please refrain from adding the_geom field as it takes a long time to render it will slow down everything!
    # In some senarios we want the return results to have only unique wdpa ids but in most cases it should be returing everything
    # if is_oecm is set to false then it returns WDPA designations for current country is set to true then returns OCEM designations
    ProtectedArea
      .select("#{'DISTINCT' if only_unique_site_ids} site_id,designation_id")
      .joins('INNER JOIN countries_protected_areas ON protected_areas.id = countries_protected_areas.protected_area_id')
      .joins(designation: :jurisdiction)
      .where(
        jurisdictions: { id: jurisdictions.any? ? jurisdictions.pluck(:id).join(',') : [] },
        protected_areas: { is_oecm: is_oecm },
        countries_protected_areas: { country_id: id }
      )
  end

  def protected_areas_per_jurisdiction(exclude_oecms: false)
    ActiveRecord::Base.connection.execute("
      SELECT jurisdictions.name, COUNT(*)
      FROM jurisdictions
      INNER JOIN designations ON jurisdictions.id = designations.jurisdiction_id
      INNER JOIN (
        SELECT protected_areas.designation_id
        FROM protected_areas
        INNER JOIN countries_protected_areas
          ON protected_areas.id = countries_protected_areas.protected_area_id
          AND countries_protected_areas.country_id = #{id}
        #{'WHERE protected_areas.is_oecm = false' if exclude_oecms}
      ) AS pas_for_country ON pas_for_country.designation_id = designations.id
      GROUP BY jurisdictions.name
    ")
  end

  def sources_per_jurisdiction
    ActiveRecord::Base.connection.execute("
      SELECT jurisdictions.name, COUNT(DISTINCT protected_areas_sources.source_id)
      FROM jurisdictions
      INNER JOIN designations ON jurisdictions.id = designations.jurisdiction_id
      INNER JOIN (
        SELECT protected_areas.id, protected_areas.designation_id
        FROM protected_areas
        INNER JOIN countries_protected_areas
          ON protected_areas.id = countries_protected_areas.protected_area_id
          AND countries_protected_areas.country_id = #{id}
      ) AS pas_for_country ON pas_for_country.designation_id = designations.id
      INNER JOIN
        protected_areas_sources
      ON
        protected_areas_sources.protected_area_id = pas_for_country.id
      GROUP BY jurisdictions.name
    ")
  end

  def protected_areas_per_iucn_category(exclude_oecms: false)
    ActiveRecord::Base.connection.execute("
      SELECT iucn_categories.id AS iucn_category_id, iucn_categories.name AS iucn_category_name, pas_per_iucn_categories.count, round((pas_per_iucn_categories.count::decimal/(SUM(pas_per_iucn_categories.count) OVER ())::decimal) * 100, 2) AS percentage
      FROM iucn_categories
      INNER JOIN (
        #{protected_areas_inner_join(:iucn_category_id, exclude_oecms)}
      ) AS pas_per_iucn_categories
        ON pas_per_iucn_categories.iucn_category_id = iucn_categories.id
    ")
  end

  def protected_areas_per_governance(exclude_oecms: false)
    ActiveRecord::Base.connection.execute("
      SELECT governances.id AS governance_id, governances.name AS governance_name, governances.governance_type AS governance_type, pas_per_governances.count AS count, round((pas_per_governances.count::decimal/(SUM(pas_per_governances.count) OVER ())::decimal) * 100, 2) AS percentage
      FROM governances
      INNER JOIN (
        #{protected_areas_inner_join(:governance_id, exclude_oecms)}
      ) AS pas_per_governances
        ON pas_per_governances.governance_id = governances.id
        ORDER BY count DESC
    ")
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
    "
      SELECT #{group_by}, COUNT(protected_areas.id) AS count
      FROM protected_areas
      INNER JOIN countries_protected_areas
        ON protected_areas.id = countries_protected_areas.protected_area_id
        AND countries_protected_areas.country_id = #{id}
      #{'WHERE protected_areas.is_oecm = false' if exclude_oecms}
      GROUP BY #{group_by}
    "
  end
end
