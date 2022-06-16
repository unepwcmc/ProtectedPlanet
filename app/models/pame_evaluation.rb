require 'csv'

class PameEvaluation < ApplicationRecord
  belongs_to :protected_area, optional: true
  belongs_to :pame_source
  has_and_belongs_to_many :countries

  validates :methodology, :year, :metadata_id, presence: true

  TABLE_ATTRIBUTES = [
    {
      title: 'Name',
      field: 'name'
    },
    {
      title: 'Designation',
      field: 'designation'
    },
    {
      title: 'WDPA ID',
      field: 'wdpa_id',
      tooltip: 'Unrestricted Protected Areas can be viewed on Protected Planet'
    },
    {
      title: 'Assessment ID',
      field: 'id'
    },
    {
      title: 'Country',
      field: 'iso3'
    },
    {
      title: 'Methodology',
      field: 'methodology'
    },
    {
      title: 'Year of assessment',
      field: 'year'
    },
    {
      title: 'Link to assessment',
      field: 'url'
    },
    {
      title: 'Metadata ID',
      field: 'metadata_id'
    }
  ].freeze

  def self.paginate_evaluations(json=nil, order=nil)
    json_params = json.nil? ? nil : JSON.parse(json)
    page = json_params.present? ? json_params["requested_page"].to_i : 1

    order = (order && ['ASC', 'DESC'].include?(order.upcase)) ? order : 'DESC'
    evaluations = generate_query(page, json_params["filters"])
    items = serialise(evaluations)
    structure_data(page, items)
  end

  def self.structure_data(page, items)
    {
      current_page: page,
      per_page: 50,
      total_entries: (items.count > 0 ? items[0][:total_entries] : 0),
      total_pages:   (items.count > 0 ? items[0][:total_pages] : 0),
      items: items
    }
  end

  def self.generate_query(page, filter_params)
    # if params are empty then return the paginated results without filtering
    return PameEvaluation.where('protected_area_id IS NOT NULL AND restricted = false').order('id ASC').paginate(page: page || 1, per_page: 50) if filter_params.empty?

    filters = filter_params.select { |hash| hash["options"].present? }

    where_params = parse_filters(filters)
    run_query(page, where_params)
  end

  def self.parse_filters(filters)
    site_ids = []
    country_ids = []
    where_params = {sites: "", methodology: "", year: "", iso3: "", type: ""}
    filters.each do |filter|
      options = filter["options"]
      case filter['name']
      when 'iso3'
        countries = options
        site_ids << countries.map{ |iso3| Country.find_by(iso_3: iso3).protected_areas.pluck(:id) }
        where_params[:sites] = site_ids.flatten.empty? ? nil : "pame_evaluations.protected_area_id IN (#{site_ids.join(',')})"
        country_ids << countries.map{ |iso3| "#{ Country.find_by(iso_3: iso3).id }" }
        where_params[:iso3] = country_ids.flatten.empty? ? nil : "countries.id IN (#{country_ids.join(',')})"
      when 'methodology'
        options = options.map{ |e| "'#{e}'" }
        where_params[:methodology] = options.empty? ? nil : "methodology IN (#{options.join(',')})"
      when 'year'
        where_params[:year] = options.empty? ? nil : "pame_evaluations.year IN (#{options.join(',')})"
      else 
        where_params[:type] = nil if options.empty? || options.length == 2
        if options.length == 1
          where_params[:type] = options[0] == 'Marine' ? "protected_areas.marine" : "protected_areas.marine = false"
        end
      end
    end
    where_params
  end

  def self.run_query(page, where_params)
    if where_params[:sites].present?
      query = PameEvaluation.connection.unprepared_statement {
        "((#{pame_evaluations_from_pa_query(where_params)}) UNION (#{pame_evaluations_from_countries_query(where_params)})) AS pame_evaluations"
      }

      PameEvaluation
      .from(query)
    else
      PameEvaluation
      .joins(:protected_area)
      .where(where_params[:methodology])
      .where(where_params[:year])
      .where(where_params[:type])
    end
    .where("protected_area_id IS NOT NULL AND restricted = false")
    .paginate(page: page || 1, per_page: 50).order('id ASC')
  end

  def self.pame_evaluations_from_pa_query(where_params)
    PameEvaluation
    .joins(:protected_area)
    .where(where_params[:sites])
    .where(where_params[:methodology])
    .where(where_params[:year])
    .where(where_params[:type])
    .to_sql
  end

  def self.pame_evaluations_from_countries_query(where_params)
    PameEvaluation
    .joins(:countries)
    .where(where_params[:iso3])
    .where(where_params[:methodology])
    .where(where_params[:year])
    .where(where_params[:type])
    .to_sql
  end

  def self.serialise(evaluations)
    evaluations.to_a.map! do |evaluation|

      wdpa_id = evaluation.protected_area&.wdpa_id || evaluation.wdpa_id
      name  = evaluation.protected_area&.name || evaluation.name
      designation = evaluation.protected_area&.designation&.name || "N/A"
      countries = evaluation.protected_area&.countries || evaluation.countries
      iso3 = countries.pluck(:iso_3).sort
      {
        current_page: evaluations.current_page,
        per_page: evaluations.per_page,
        total_entries: evaluations.total_entries,
        total_pages: evaluations.total_pages,
        id: evaluation.id,
        wdpa_id: wdpa_id,
        wdpa_url: Rails.application.routes.url_helpers.protected_area_path(wdpa_id),
        restricted: evaluation.restricted,
        iso3: iso3,
        methodology: evaluation.methodology,
        year: evaluation.year.to_s,
        url: evaluation.url,
        metadata_id: evaluation.metadata_id,
        source_id: evaluation.pame_source&.id,
        name: name,
        designation: designation,
        data_title: evaluation.pame_source&.data_title,
        resp_party: evaluation.pame_source&.resp_party,
        language: evaluation.pame_source&.language,
        source_year: evaluation.pame_source&.year
      }
    end
  end

  def self.sources_to_json
    sources = PameSource.all.order(id: :asc)
    sources.to_a.map! do |source|
      {
        id: source.id,
        data_title: source.data_title,
        resp_party: source.resp_party,
        year: source.year,
        language: source.language
      }
    end.to_json
  end

  def self.filters_to_json
    unique_methodologies = PameEvaluation.pluck(:methodology).uniq.sort
    unique_iso3 = Country.pluck(:iso_3).compact.uniq.sort
    unique_year = PameEvaluation.pluck(:year).uniq.map(&:to_s).sort

    [
      {
        name: 'methodology',
        title: 'Methodology',
        options: unique_methodologies,
        type: 'multiple'
      },
      {
        name: "iso3",
        title: "Country",
        options: unique_iso3,
        type: 'multiple'
      },
      {
        name: "year",
        title: "Year of assessment",
        options: unique_year,
        type: 'multiple'
      },
      {
        name: 'type',
        title: 'Type',
        options: ['Marine', 'Terrestrial'],
        type: 'multiple'
      }
    ].to_json
  end

  def self.generate_csv(where_statement, restricted_where_statement)
    where_statement = where_statement.empty? ? '' : "WHERE #{where_statement}"
    restricted_where_statement = restricted_where_statement.empty? ? '' : "WHERE #{restricted_where_statement}"
    query = <<-SQL
      SELECT pame_evaluations.id AS id,
             pame_evaluations.metadata_id AS metadata_id,
             pame_evaluations.url AS url,
             pame_evaluations.year AS evaluation_year,
             pame_evaluations.methodology AS methodology,
             protected_areas.wdpa_id AS wdpa_id,
             ARRAY_TO_STRING(ARRAY_AGG(countries.iso_3),';') AS countries,
             protected_areas.name AS site_name,
             designations.name AS designation,
             pame_sources.data_title AS data_title,
             pame_sources.resp_party AS resp_party,
             pame_sources.year AS source_year,
             pame_sources.language AS language
             FROM pame_evaluations
             INNER JOIN protected_areas ON pame_evaluations.protected_area_id = protected_areas.id
             LEFT JOIN pame_sources ON pame_evaluations.pame_source_id = pame_sources.id
               INNER JOIN countries_protected_areas ON protected_areas.id = countries_protected_areas.protected_area_id
               INNER JOIN countries ON countries_protected_areas.country_id = countries.id
               INNER JOIN designations ON protected_areas.designation_id = designations.id
               #{where_statement}
               GROUP BY pame_evaluations.id, protected_areas.wdpa_id, protected_areas.name, designation, pame_sources.data_title,
                        pame_sources.resp_party, pame_sources.year, pame_sources.language

       /*        UNION

        SELECT pame_evaluations.id AS id,
               pame_evaluations.metadata_id AS metadata_id,
               pame_evaluations.url AS url,
               pame_evaluations.year AS evaluation_year,
               pame_evaluations.methodology AS methodology,
               pame_evaluations.wdpa_id AS wdpa_id,
               ARRAY_TO_STRING(ARRAY_AGG(countries.iso_3),';') AS countries,
               pame_evaluations.name AS site_name,
               NULL AS designation,
               pame_sources.data_title AS data_title,
               pame_sources.resp_party AS resp_party,
               pame_sources.year AS source_year,
               pame_sources.language AS language
               FROM pame_evaluations
               INNER JOIN pame_sources ON pame_evaluations.pame_source_id = pame_sources.id
               INNER JOIN countries_pame_evaluations ON pame_evaluations.id = countries_pame_evaluations.pame_evaluation_id
               INNER JOIN countries ON countries_pame_evaluations.country_id = countries.id
               #{restricted_where_statement}
               GROUP BY pame_evaluations.id, wdpa_id, pame_evaluations.name, designation, pame_sources.data_title,
                        pame_sources.resp_party, pame_sources.year, pame_sources.language;
      */
      SQL
    evaluations = ActiveRecord::Base.connection.execute(query)

    csv_string = CSV.generate(encoding: 'UTF-8') do |csv_line|

      evaluation_columns = PameEvaluation.new.attributes.keys
      evaluation_columns << "evaluation_id"

      excluded_attributes = ["assessment_is_public", "restricted", "protected_area_id", "pame_source_id", "created_at", "updated_at", "id", "site_id", "source_id"]

      evaluation_columns.delete_if { |k, v| excluded_attributes.include? k }

      additional_columns = ["iso3", "designation", "source_data_title", "source_resp_party", "source_year", "source_language"]
      evaluation_columns << additional_columns.map{ |e| "#{e}" }

      csv_line << evaluation_columns.flatten

      evaluations.each do |evaluation|
        evaluation_attributes = PameEvaluation.new.attributes

        evaluation_attributes.delete_if { |k, v| excluded_attributes.include? k }

        evaluation_attributes["evaluation_id"] = evaluation["id"]
        evaluation_attributes["metadata_id"] = evaluation["metadata_id"]
        evaluation_attributes["url"] = evaluation["url"] || "N/A"
        evaluation_attributes["year"] = evaluation["evaluation_year"]
        evaluation_attributes["methodology"] = evaluation["methodology"]
        evaluation_attributes["wdpa_id"] = evaluation["wdpa_id"]
        evaluation_attributes["iso_3"] = evaluation['countries']
        evaluation_attributes["name"] = evaluation["site_name"]
        evaluation_attributes["designation"] = evaluation["designation"] || "N/A"
        evaluation_attributes["source_data_title"] = evaluation["data_title"]
        evaluation_attributes["source_resp_party"] = evaluation["resp_party"]
        evaluation_attributes["source_year"] = evaluation["source_year"]
        evaluation_attributes["source_language"] = evaluation["language"]

        evaluation_attributes = evaluation_attributes.values.map{ |e| "#{e}" }
        csv_line << evaluation_attributes
      end
    end
    csv_string
  end

  def self.to_csv(json = nil)
    json_params = json.nil? ? nil : JSON.parse(json)
    filter_params = json_params["_json"].nil? ? nil : json_params["_json"]
    
    where_statement = []
    restricted_where_statement = []
    where_params = parse_filters(filter_params)
    where_params.map do |k, v|
      where_statement << v unless v.nil?
      restricted_where_statement << v if !v.nil? && k != :sites
    end

    where_statement << '(pame_evaluations.protected_area_id IS NOT NULL AND restricted = false)'
    where_statement = where_statement.join(' AND ')

    restricted_where_statement << '(pame_evaluations.protected_area_id IS NULL AND restricted = false)'
    restricted_where_statement = restricted_where_statement.join(' AND ')

    generate_csv(where_statement, restricted_where_statement)
  end

  def self.last_csv_update_date
    pame_data_csvs = Dir.glob("#{Rails.root}/lib/data/seeds/pame_data*")
    latest_pame_csv = pame_data_csvs.sort.last.split('_').last
    latest_pame_csv.split('.').first.to_date
  end
end


