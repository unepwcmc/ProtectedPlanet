class GreenListController < ApplicationController
  include MapHelper
  # Show page for green listed protected areas
  # Will only show if that area is a green listed area, otherwise redirects to wdpa page

  # As of 01Apr2025 we do not have enough data to show so hidding see app/views/green_list/index.html.erb
  # before_action :most_protected_areas
  before_action :get_green_list_sites

  def index
    @download_options = helpers.download_options(%w[csv shp gdb], 'general', Download::Requesters::General::TYPE_MAP[:all_greenlisted_wdpca])

    stats = green_list_statistics
    @pas_km = stats['green_list_area']
    @pas_percent = stats['green_list_perc']
    @pas_total = stats['green_list_count']

    # As of 01Apr2025 we do not have enough data to show so hidding
    # # Starts from 2000
    # @protectedAreaGrowth =
    #   {
    #     title: I18n.t('charts.legend.coverage_km2'),
    #     units: I18n.t('charts.units.km2'),
    #     datapoints: ProtectedArea.greenlist_coverage_growth(2000)
    #   }.to_json

    @total_area_percent = GlobalStatistic.global_oecms_pas_coverage_percentage

    @filters = SearchAreaLinkFilters.green_list_status_filters

    @green_list_view_all_url = search_areas_path(filters: SearchAreaLinkFilters.green_list_status_filters)

    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'pa_or_any_its_parcels_is_greenlisted',
      point_query_services: point_query_services
    }
  end

  private

  def green_list_statistics
    @green_list_statistics ||= GlobalStatistic.green_list_stats
  end

  def map_overlays
    overlays(%w[greenlist_terrestrial greenlist_marine], {
      greenlist_terrestrial: {
        queryString: greenlist_query_string(terrestrial_green_list_area_ids)
      },
      greenlist_marine: {
        queryString: greenlist_query_string(marine_green_list_area_ids)
      }
    })
  end

  def point_query_services
    site_ids = pas_with_green_list_on_self_only.pluck(:site_id)
    wdpa_services_for_point_query.map do |service|
      service.merge({
        queryString: site_ids_where_query(site_ids)
      })
    end
  end

  # As of 01Apr2025 we do not have enough data to show so hidding see app/views/green_list/index.html.erb
  # def most_protected_areas
  #   @regionsTopCountries = Region.without_global.map do |region|
  #     RegionPresenter.new(region).top_gl_coverage_countries
  #   end.compact.to_json
  # end

  def pas_with_green_list_on_self_only
    @pas_with_green_list_on_self_only ||= ProtectedArea.pas_with_green_list_on_self_only
  end

  def get_green_list_sites
    @example_greenlist ||= pas_with_green_list_on_self_only.take(3)
  end

  def terrestrial_green_list_area_ids
    pas_with_green_list_on_self_only.terrestrial_areas.pluck(:site_id)
  end

  def marine_green_list_area_ids
    pas_with_green_list_on_self_only.marine_areas.pluck(:site_id)
  end
end
