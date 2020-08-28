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
      column_name: 'percentage_oecms_pa_type_cover'
    },
    effectively_managed: {
      id: 'effectively_managed',
      name: 'Effectively managed',
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
    @search_id, @search_type = sanitise_search_term
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
      url = "/#{record['obj_type']}/#{record['iso']}"
      hash = {
        title: record['name'],
        url: url,
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
    sorted.map do |i|
      id = "#{i['id']}-#{i['obj_type']}"
      {
        id: id,
        name: i['name']
      }
    end
  end

  private

  def sorted
    obj_type = @search_type == 'id' ? "AND obj_type = 'country'" : ''
    default_order = 'ORDER BY region_name, obj_type DESC, name ASC NULLS LAST'
    search = @search_id.present? ? "WHERE #{@search_type} = #{@search_id} #{obj_type}" : ''
    query = "SELECT * FROM aichi11_target_dashboard_view #{search} #{default_order}"
    _data = ActiveRecord::Base.connection.execute(query)

    if @params[:sort_by].present?
      sort_terms = sort_by.split('+')
      _data = _data.sort_by do |d|
        if sort_terms.length > 1
          sort_terms.inject(0.0) { |sum, x| sum + (d[x] || 0.0) }
        else
          d[sort_terms.first]
        end
      end
      order.downcase == 'desc'? _data.reverse : _data
    else
      _data.to_a
    end
  end

  def sorted_and_paginated
    sorted.paginate(page: page, per_page: per_page)
  end

  def sort_by
    # Splitting by / because of the country/region parameter
    _sort_by = @params[:sort_by] ? @params[:sort_by].split('/').first : ''
    sort_field_land = 'percentage_pa_land_cover'
    sort_field_marine = 'percentage_pa_marine_cover'
    case _sort_by
    when 'coverage'
      "#{sort_field_land}+#{sort_field_marine}"
    when 'effectively_managed'
      "pame_#{sort_field_land}+pame_#{sort_field_marine}"
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
      id: stat[:id],
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
    target = is_importance_region?(stat_name, record) ? nil : Aichi11Target.instance.public_send(target_column)
    {
      title: type.capitalize,
      value: value,
      target: target,
      colour: type
    }
  end

  def sanitise_search_term
    return ['', ''] unless @params[:search_id]
    _id, _obj_type = @params[:search_id].split('-')
    id = ['__UNDEFINED__', 'SEARCHID', '', nil].include?(_id) ? '' : _id
    obj_type = _obj_type == 'region' ? 'region_id' : 'id'

    [id, obj_type]
  end

  def is_importance_region?(stat_name, record)
    (stat_name.to_s == 'importance' && record['obj_type'] == 'region')
  end
end
