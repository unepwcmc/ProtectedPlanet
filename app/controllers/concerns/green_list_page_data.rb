module GreenListPageData
  extend ActiveSupport::Concern
  include MapHelper

  private

  def prepare_green_list_tab_data
    @download_options = helpers.download_options(%w[csv shp gdb], 'general', 'greenlist')

    stats = green_list_statistics
    @greenlisted_pas_km = stats['green_list_area']
    @greenlisted_pas_percent = stats['green_list_perc']
    @greenlisted_pas_total_count = stats['green_list_count']
    @global_oecms_pas_coverage_percentage = GlobalStatistic.global_oecms_pas_coverage_percentage
    @green_list_view_all_url = search_areas_path(filters: ::SearchAreaLinkFilters.green_list_status_filters)
    @example_greenlist = pas_with_green_list_on_self_only.take(3)
    @green_list_map = {
      overlays: MapOverlaysSerializer.new(green_list_map_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'pa_or_any_its_parcels_is_greenlisted',
      point_query_services: green_list_point_query_services,
      popup_attributes: map_yml[:popup_attributes],
      disclaimer: map_yml[:disclaimer]
    }
  end

  def green_list_statistics
    @green_list_statistics ||= GlobalStatistic.green_list_stats
  end

  def green_list_map_overlays
    overlays(%w[greenlist_terrestrial greenlist_marine], {
      greenlist_terrestrial: {
        queryString: greenlist_site_pids_query_string(green_list_site_pids(marine: false))
      },
      greenlist_marine: {
        queryString: greenlist_site_pids_query_string(green_list_site_pids(marine: true))
      }
    })
  end

  def green_list_point_query_services
    site_pids = green_list_site_pids
    all_services_for_point_query.map do |service|
      service.merge(queryString: site_pids_where_query(site_pids))
    end
  end

  def pas_with_green_list_on_self_only
    @pas_with_green_list_on_self_only ||= ProtectedArea.pas_with_green_list_on_self_only
  end

  def green_list_site_pids(marine: nil)
    (green_list_pa_site_pids(marine: marine) + green_list_parcel_site_pids(marine: marine)).uniq
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
