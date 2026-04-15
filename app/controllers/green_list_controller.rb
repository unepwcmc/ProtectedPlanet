class GreenListController < ApplicationController
  include MapHelper
  # Show page for green listed protected areas
  # Will only show if that area is a green listed area, otherwise redirects to wdpa page

  before_action :get_green_list_sites

  def index
    @download_options = helpers.download_options(%w[csv shp gdb], 'general', 'greenlist')

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
        queryString: greenlist_site_pids_query_string(green_list_site_pids(marine: false))
      },
      greenlist_marine: {
        queryString: greenlist_site_pids_query_string(green_list_site_pids(marine: true))
      }
    })
  end

  def point_query_services
    site_pids = green_list_site_pids
    wdpa_services_for_point_query.map do |service|
      service.merge({
        # We need this so it will only return the site pids that are green listed, without this it will return any site at the point.
        queryString: site_pids_where_query(site_pids)
      })
    end
  end

  def pas_with_green_list_on_self_only
    @pas_with_green_list_on_self_only ||= ProtectedArea.pas_with_green_list_on_self_only
  end

  def pas_with_green_list_on_self_or_any_parcel
    @pas_with_green_list_on_self_or_any_parcel ||= ProtectedArea.pas_with_green_list_on_self_or_any_parcel
  end

  def get_green_list_sites
    @example_greenlist ||= pas_with_green_list_on_self_only.take(3)
  end

  def green_list_site_pids(marine: nil)
    pa_site_pids = green_list_pa_site_pids(marine: marine)
    parcel_site_pids = green_list_parcel_site_pids(marine: marine)
    (pa_site_pids + parcel_site_pids).uniq
  end

  def green_list_pa_site_pids(marine: nil)
    scope = pas_with_green_list_on_self_only
    scope = with_optional_marine_filter(scope, marine)

    scope.pluck(:site_pid)
  end

  def green_list_parcel_site_pids(marine: nil)
    scope = ProtectedAreaParcel.greenlisted_parcels
    scope = with_optional_marine_filter(scope, marine)

    scope.pluck(:site_pid)
  end

  def with_optional_marine_filter(scope, marine)
    return scope if marine.nil?

    marine ? scope.marine_areas : scope.terrestrial_areas
  end
end
