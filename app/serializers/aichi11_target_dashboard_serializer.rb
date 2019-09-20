require 'will_paginate/array'
class Aichi11TargetDashboardSerializer < CountrySerializer
  PER_PAGE = 15.freeze
  STATS = {
    country: {
      id: 'country/region',
      name: 'Country/Region',
      column_name: 'name'
    },
    coverage: {
      id: 'coverage',
      name: 'Coverage',
      relation: 'country_statistic',
      column_name: 'percentage_pa_type_cover'
    },
    effectively_managed: {
      id: 'effectively_managed',
      name: 'Effectiveley managed',
      relation: 'pame_statistic',
      column_name: 'pame_percentage_pa_type_cover'
    },
    well_connected: {
      id: 'well_connected',
      name: 'Well connected',
      relation: 'country_statistic',
      column_name: 'percentage_well_connected',
    },
    importance: {
      id: 'importance',
      name: 'Areas of importance for biodiversity',
      relation: 'country_statistic',
      column_name: 'percentage_importance'
    }
  }.freeze

  def initialize(params={}, data = nil)
    super(params, data)
    @search_term = sanitise_search_term
  end

  def serialize
    serialized_data = {
      page: page,
      per_page: per_page,
      items: [],
      total_entries: sorted.length
    }
    # Loop through records
    sorted_and_paginated.map do |record|
      hash = {
        title: record['name'],
        url: "/country/#{record['iso']}",
        obj_type: record['obj_type'],
        stats: []
      }

      STATS.reject { |key, value| key == :country }.map do |stat_name, stat|
        hash[:stats] << body_stats(stat, stat_name, record)
      end
      serialized_data[:items] << hash.dup
    end
    serialized_data
  end

  def serialize_head
    head.to_json
  end

  def serialize_options
    @params[:sort_by] ||= 'name'
    @params[:order] ||= 'asc'
    sorted.map { |i| {id: i['iso'], name: i['name'], obj_type: i['obj_type'] } }
  end

  private

  def sorted
    search = @search_term.present? ? "WHERE iso = '#{@search_term}' LIMIT 1" : ''
    query = "SELECT * FROM aichi11_target_dashboard_view #{search}"
    _data = ActiveRecord::Base.connection.execute(query)

    _data = _data.sort_by { |d| d[sort_by] }
    order.downcase == 'desc'? _data.reverse : _data
  end

  def sorted_and_paginated
    sorted.paginate(page: page, per_page: per_page)
  end

  def sort_by
    # Splitting by / for the country/region parameter
    _sort_by = @params[:sort_by] ? @params[:sort_by].split('/').first : ''
    sort_field_land = 'percentage_pa_land_cover'
    sort_field_marine = 'percentage_pa_marine_cover'
    case _sort_by
    when 'coverage'
      "(#{sort_field_land} + #{sort_field_marine})"
    when 'effectively_managed'
      "(pame_#{sort_field_land} + pame_#{sort_field_marine})"
    else
      if _sort_by.present? && STATS[_sort_by.to_sym].present?
        STATS[_sort_by.to_sym][:column_name]
      else
        super
      end
    end
  end

  def head
    STATS.map do |key, stat|
      {
        id: stat[:id],
        title: stat[:name]
      }
    end
  end

  def body_stats(stat, stat_name, record)
    {
      title: stat[:name],
      charts: charts(stat, stat_name, record)
    }
  end

  def charts(stat, stat_name, record)
    if stat[:column_name].include?('type')
      [
        chart_hash(stat, stat_name, record, 'terrestrial'),
        chart_hash(stat, stat_name, record, 'marine')
      ]
    else
      [ chart_hash(stat, stat_name, record, 'global') ]
    end
  end

  def chart_hash(stat, stat_name, record, type)
    column_type = type == 'terrestrial' ? 'land' : type == 'global' ? '' : 'marine'
    _column_name = stat[:column_name].gsub(/type/, column_type)
    target_column = "#{stat_name}_#{type}"

    value = record[_column_name] || 0
    {
      title: type.capitalize,
      value: value,
      target: Aichi11Target.instance.public_send(target_column),
      colour: type
    }
  end

  def sanitise_search_term
    term = @params[:search_term]
    ['__UNDEFINED__', '', nil].include?(term) ? '' : term
  end
end
