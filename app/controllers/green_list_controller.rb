class GreenListController < ApplicationController
  include MapHelper
  # Show page for green listed protected areas
  # Will only show if that area is a green listed area, otherwise redirects to wdpa page

  before_action :most_protected_areas
  before_action :get_green_list_sites

  def index
    @download_options = helpers.download_options(['csv', 'shp', 'gdb'], 'general', 'greenlist')

    stats = green_list_statistics
    @pas_km = stats['green_list_area']
    @pas_percent = stats['green_list_perc']
    @pas_total = stats['green_list_count']

    # Starts from 2000
    @protectedAreaGrowth = 
    {
      title: I18n.t('charts.legend.coverage_km2'),
      units: I18n.t('charts.units.km2'),
      datapoints: ProtectedArea.greenlist_coverage_growth(2000)
    }.to_json 
    
    @total_area_percent = GlobalStatistic.global_oecms_pas_coverage_percentage

    @filters = {
      db_type: ['wdpa', 'oecm'],
      special_status: ['is_green_list', 'is_green_list_candidate']
    }

    @greenListViewAllUrl = search_areas_path(filters: { special_status: ['is_green_list', 'is_green_list_candidate']} )

    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'is_green_list',
      point_query_services: point_query_services
    }
  end

  private

  def green_list_statistics
    @green_list_statistics ||= GlobalStatistic.green_list_stats
  end

  def map_overlays
    overlays(['greenlist_terrestrial', 'greenlist_marine'], {
      greenlist_terrestrial: {
        queryString: greenlist_query_string(terrestrial_green_list_area_ids)
      },
      greenlist_marine: {
        queryString: greenlist_query_string(marine_green_list_area_ids)
      }
    })
  end

  def point_query_services
    all_services_for_point_query.map do |service|
      service.merge({
        queryString: wdpaid_where_query(green_list_areas.map(&:wdpa_id))
      })
    end
  end

  def most_protected_areas
    @regionsTopCountries = Region.without_global.map do |region|
      RegionPresenter.new(region).top_gl_coverage_countries
    end.compact.to_json
  end

  def green_list_areas
    @green_list_areas ||= ProtectedArea.green_list_areas
  end

  def get_green_list_sites
    @example_greenlist ||= green_list_areas.take(3)
  end

  def terrestrial_green_list_area_ids
    green_list_areas.terrestrial_areas.map(&:wdpa_id)
  end

  def marine_green_list_area_ids
    green_list_areas.marine_areas.map(&:wdpa_id)
  end
end
