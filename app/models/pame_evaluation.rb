require 'csv'

class PameEvaluation < ApplicationRecord
  belongs_to :protected_area, optional: true
  belongs_to :protected_area_parcel, optional: true
  belongs_to :pame_source
  belongs_to :pame_method, optional: true
  has_and_belongs_to_many :countries

  validates :method, :asmt_year, :asmt_id, presence: true

  HAS_AREA_OR_PARCEL_CONDITION = '(protected_area_id IS NOT NULL OR protected_area_parcel_id IS NOT NULL)'.freeze
  HAS_AREA_OR_PARCEL_CONDITION_WITH_TABLE = 'pame_evaluations.protected_area_id IS NOT NULL OR pame_evaluations.protected_area_parcel_id IS NOT NULL'.freeze
  QUERY_ORDER = 'asmt_id ASC'.freeze

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
      title: 'SITE_ID',
      field: 'site_id',
      tooltip: 'Unrestricted Protected Areas can be viewed on Protected Planet'
    },
    {
      title: 'ASMT_ID',
      field: 'asmt_id'
    },
    {
      title: 'Country',
      field: 'country'
    },
    {
      title: 'Method',
      field: 'method'
    },
    {
      title: 'Year of assessment',
      field: 'asmt_year'
    },
    {
      title: 'Link to assessment',
      field: 'asmt_url',
    },
    {
      title: 'EFF_METAID',
      field: 'eff_metaid'
    }
  ].freeze

  def self.paginate_evaluations(json = nil)
    json_params = json.nil? ? nil : JSON.parse(json)
    page = json_params.present? ? json_params['requested_page'].to_i : 1

    evaluations = generate_query(page, json_params['filters'])
    items = serialise(evaluations)
    structure_data(page, items)
  end

  def self.structure_data(page, items)
    {
      current_page: page,
      per_page: 50,
      total_entries: (items.count > 0 ? items[0][:total_entries] : 0),
      total_pages: (items.count > 0 ? items[0][:total_pages] : 0),
      items: items
    }
  end

  def self.generate_query(page, filter_params)
    filters = (filter_params || []).select { |hash| hash['options'].present? }
    where_params = parse_filters(filters)
    run_query(where_params, page)
  end

  def self.parse_filters(filters)
    where_params = { method: nil, year: nil, country: nil, type: nil }

    filters.each do |filter|
      options = filter['options']

      case filter['name']
      when 'country'
        country_ids = options.flat_map do |country_name|
          country = Country.find_by(name: country_name)
          # include the parent country id for the overseas territory because PAME evaluation is assigned to the parent country
          [country&.id, country&.country_id].compact
        end

        where_params[:country] = if country_ids.empty?
                                   '1 = 0' # no matching countries → no results
                                 else
                                   "countries.id IN (#{country_ids.join(',')})"
                                 end
      when 'method'
        quoted = options.map { |e| ActiveRecord::Base.connection.quote(e) }
        where_params[:method] = quoted.empty? ? nil : "pame_methods.name IN (#{quoted.join(',')})"
      when 'year'
        where_params[:year] = options.empty? ? nil : "pame_evaluations.asmt_year IN (#{options.join(',')})"
      else
        if options.length == 1
          where_params[:type] = if options[0] == 'Marine'
                                  'COALESCE(protected_areas.marine, protected_area_parcels.marine)'
                                else
                                  'COALESCE(protected_areas.marine, protected_area_parcels.marine) = false'
                                end
        end
      end
    end

    where_params
  end

  def self.run_query(where_params, page_number)
    scope = PameEvaluation.left_joins(:protected_area, :protected_area_parcel, :pame_method)
    scope = scope.joins(:countries) if where_params[:country].present?

    scope = scope.where(where_params[:method]) if where_params[:method].present?
    scope = scope.where(where_params[:year])   if where_params[:year].present?
    scope = scope.where(where_params[:type])    if where_params[:type].present?
    scope = scope.where(where_params[:country]) if where_params[:country].present?

    scope.where(HAS_AREA_OR_PARCEL_CONDITION).order(QUERY_ORDER).paginate(page: page_number || 1, per_page: 50)
  end

  def self.serialise(evaluations)
    evaluations.to_a.map! do |evaluation|
      area = evaluation.protected_area_parcel || evaluation.protected_area
      site_id = area&.site_id
      name = evaluation.name
      designation = area&.designation&.name || 'N/A'
      countries = evaluation.countries
      country_names = countries.pluck(:name).sort
      {
        current_page: evaluations.current_page,
        per_page: evaluations.per_page,
        total_entries: evaluations.total_entries,
        total_pages: evaluations.total_pages,
        id: evaluation.id,
        # TODO: Remove this after PAME data migration is complete (After PAME is using data from data management portal)
        asmt_id: evaluation.asmt_id || evaluation.id,
        site_id: site_id,
        site_pid: area&.site_pid,
        pa_site_url: Rails.application.routes.url_helpers.protected_area_path(site_id),
        country: country_names,
        method: evaluation.pame_method&.name,
        asmt_year: evaluation.asmt_year.to_s,
        asmt_url: evaluation.asmt_url,
        eff_metaid: evaluation.pame_source&.id,
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
    methods = PameMethod.pluck(:name).compact.sort
    unique_countries = Country.pluck(:name).compact.uniq.sort
    unique_year = PameEvaluation.pluck(:asmt_year).uniq.map(&:to_s).sort

    [
      {
        name: 'method',
        title: 'Method',
        options: methods,
        type: 'multiple'
      },
      {
        name: 'country',
        title: 'Country',
        options: unique_countries,
        type: 'multiple'
      },
      {
        name: 'year',
        title: 'Year of assessment',
        options: unique_year,
        type: 'multiple'
      },
      {
        name: 'type',
        title: 'Type',
        options: %w[Marine Terrestrial],
        type: 'multiple'
      }
    ].to_json
  end

  def self.generate_csv(where_statement)
    where_statement = where_statement.blank? ? '' : "WHERE #{where_statement}"
    query = <<-SQL
      SELECT
        pame_evaluations.asmt_id AS asmt_id,
        pame_evaluations.site_id AS site_id,
        pame_evaluations.site_pid AS site_pid,
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT countries.name), ';') AS country,
        COALESCE(protected_areas.marine, protected_area_parcels.marine) AS site_type,
        pame_evaluations.name AS name_eng,
        COALESCE(parcel_designations.name, pa_designations.name, 'N/A') AS desig_en,
        pame_evaluations.method AS method,
        pame_evaluations.asmt_year AS asmt_year,
        pame_evaluations.submit_year AS submityear,
        pame_evaluations.verif_eff AS verif_eff,
        COALESCE(parcel_gl.status, pa_gl.status) AS gl_status,
        COALESCE(pame_evaluations.asmt_url, 'N/A') AS asmt_url,
        pame_evaluations.info_url AS info_url,
        pame_evaluations.gov_act AS gov_act,
        pame_evaluations.gov_asmt AS gov_asmt,
        pame_evaluations.dp_bio AS dp_bio,
        pame_evaluations.dp_other AS dp_other,
        pame_evaluations.mgmt_obset AS mgmt_obset,
        pame_evaluations.mgmt_obman AS mgmt_obman,
        pame_evaluations.mgmt_adapt AS mgmt_adapt,
        pame_evaluations.mgmt_staff AS mgmt_staff,
        pame_evaluations.mgmt_budgt AS mgmt_budgt,
        pame_evaluations.mgmt_thrts AS mgmt_thrts,
        pame_evaluations.mgmt_mon AS mgmt_mon,
        pame_evaluations.out_bio AS out_bio,
        pame_sources.id AS eff_metaid,
        pame_sources.data_title AS source_data_title,
        pame_sources.resp_party AS source_resp_party,
        pame_sources.year AS source_year,
        pame_sources.language AS source_language
      FROM pame_evaluations
      LEFT JOIN pame_sources ON pame_evaluations.pame_source_id = pame_sources.id
      LEFT JOIN countries_pame_evaluations ON pame_evaluations.id = countries_pame_evaluations.pame_evaluation_id
      LEFT JOIN countries ON countries_pame_evaluations.country_id = countries.id
      LEFT JOIN pame_methods ON pame_evaluations.pame_method_id = pame_methods.id
      LEFT JOIN protected_areas ON pame_evaluations.protected_area_id = protected_areas.id
      LEFT JOIN protected_area_parcels ON pame_evaluations.protected_area_parcel_id = protected_area_parcels.id
      LEFT JOIN green_list_statuses pa_gl ON pa_gl.id = protected_areas.green_list_status_id
      LEFT JOIN green_list_statuses parcel_gl ON parcel_gl.id = protected_area_parcels.green_list_status_id
      LEFT JOIN designations pa_designations ON pa_designations.id = protected_areas.designation_id
      LEFT JOIN designations parcel_designations ON parcel_designations.id = protected_area_parcels.designation_id
      #{where_statement}
      GROUP BY
        pame_evaluations.id,
        pame_sources.id,
        pa_designations.name,
        parcel_designations.name,
        COALESCE(protected_areas.marine, protected_area_parcels.marine),
        pa_gl.status,
        parcel_gl.status
    SQL
    evaluations = ActiveRecord::Base.connection.exec_query(query)
    columns = evaluations.columns

    CSV.generate(encoding: 'UTF-8') do |csv_line|
      # Use SQL column order, but uppercase for header row
      csv_line << columns.map(&:upcase)

      evaluations.each do |evaluation|
        csv_line << columns.map do |col|
          value = evaluation[col]

          if col == 'site_type'
            # Convert boolean-ish site_type to Marine / Terrestrial
            value = value ? 'Marine' : 'Terrestrial'
          end

          value
        end
      end
    end
  end

  def self.to_csv(json = nil)
    json_params = json.present? ? JSON.parse(json) : {}

    # Support both shapes:
    # - { "filters": [ ... ] }  (like list/index)
    # - { "_json": [ ... ] }    (raw array in params[:_json])
    # - [ ... ]                 (JSON is already an array)
    raw_filters =
      if json_params.is_a?(Hash)
        json_params['filters'] || json_params['_json'] || []
      else
        json_params
      end

    filters = (raw_filters || []).select { |hash| hash['options'].present? }
    where_params = parse_filters(filters)

    where_statement_parts = []
    where_params.each_value do |v|
      where_statement_parts << v if v.present?
    end

    where_statement_parts << "(#{HAS_AREA_OR_PARCEL_CONDITION_WITH_TABLE})"
    where_statement = where_statement_parts.join(' AND ')

    generate_csv(where_statement)
  end

  def self.last_csv_update_date
    pame_data_csvs = Dir.glob("#{Rails.root}/lib/data/seeds/pame_data*")
    latest_pame_csv = pame_data_csvs.sort.last.split('_').last
    latest_pame_csv.split('.').first.to_date
  end
end
