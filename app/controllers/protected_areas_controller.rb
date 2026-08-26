class ProtectedAreasController < ApplicationController
  after_action :record_visit
  after_action :enable_caching
  include MapHelper

  def show
    id = params[:id]
    raise_404 unless params[:format].nil?

    @download_options = helpers.download_options(%w[csv shp gdb pdf], 'protected_area', id)

    # If found by slug, redirect to search page
    # This is to overcome possible issues with PAs with same name/slug and different SITE ID
    pa = ProtectedArea.find_by(slug: id)
    redirect_to search_areas_path(search_term: pa.name), status: :moved_permanently and return if pa

    @protected_area = ProtectedArea.find_by(site_id: id.to_i)
    @protected_area || raise_404
    @presenter = ProtectedAreaPresenter.new @protected_area
    @countries = @protected_area.countries.without_geometry

    @locations = get_locations
    @wdpa_other = get_other_sites

    @otherWdpasViewAllUrl = determine_search_path(@protected_area)

    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize,
      point_query_services: point_query_services,
      title: map_yml[:title],
      popup_attributes: map_yml[:popup_attributes],
      disclaimer: map_yml[:disclaimer]
    }

    @map_options = {
      map: {
        boundsUrl: @protected_area.extent_url
      }
    }

    helpers.opengraph_title_and_description_with_suffix(@protected_area.name)
    set_page_meta(title: @protected_area.name, description: meta_description)
    @structured_data = structured_data_presenter.protected_area(@protected_area, countries: @countries, description: meta_description)

    respond_to do |format|
      format.html
    end
  end

  private

  def meta_description
    t('meta.protected_area.description', name: @protected_area.name)
  end

  def map_overlays
    overlays(['individual_site'], {
      individual_site: @protected_area.arcgis_layer_config
    })
  end

  def point_query_services
    all_services_for_point_query.map do |service|
      service.merge({
        queryString: site_ids_where_query([@protected_area.site_id])
      })
    end
  end

  def get_locations
    locations = []

    if @countries.any?
      @countries.each_with_index do |country, _i|
        locations << ActionController::Base.helpers.link_to(country.name, country_path(country.iso_3))
      end
    else
      locations << 'Areas Beyond National Jurisdiction'
    end

    locations.join(', ')
  end

  # Popularity counter, keyed by month. The sitemap now advertises every /:id page
  # (see lib/modules/sitemap.rb), so a full crawl would tick all ~500k sites once.
  # That is uniform enough not to reorder the ranking, but this counter is meant to
  # measure people, and a crawler revisiting a slice of the catalogue is not.
  #
  # Headless Chrome is in the list because the PDF rasterizer renders this page to
  # produce a protected area PDF: that visit was already counted when the person
  # loaded the page they exported from.
  NON_HUMAN_USER_AGENT = /bot|crawl|spider|slurp|headlesschrome|facebookexternalhit/i

  def record_visit
    return if @protected_area.nil?
    # User agent is the only signal available on the request path -- verifying a
    # crawler properly means a reverse DNS lookup per request. A spoofed agent
    # loses one increment, which is the cheaper way to be wrong here.
    return if request.user_agent.to_s.match?(NON_HUMAN_USER_AGENT)

    year_month = DateTime.now.strftime('%m-%Y')
    $redis.zincrby(year_month, 1, @protected_area.site_id)
  end

  OTHER_SITES = 3
  def get_other_sites
    # Get country sites if the site has 1 country, get transboundary sites otherwise
    other_sites = @countries.length == 1 ? country_own_sites : transboundary_sites
    # If the sites taken are less than 3 get more random sites until 3 is reached
    other_sites.count < OTHER_SITES ? other_sites.concat(remainder_sites(other_sites.count)) : other_sites
  end

  def transboundary_sites
    ProtectedArea.without_geometry.all_except(@protected_area.id).transboundary_sites.take(OTHER_SITES)
  end

  def country_own_sites
    @countries.first.protected_areas.without_geometry.all_except(@protected_area.id).take(OTHER_SITES)
  end

  def remainder_sites(other_sites)
    ProtectedArea.without_geometry.all_except(@protected_area.id).take(OTHER_SITES - other_sites)
  end

  def determine_search_path(area)
    if area.is_transboundary
      search_areas_path(filters: SearchAreaLinkFilters.special_status_is_transboundary_filters)
    else
      filters = @countries.empty? ? {} : { filters: location_filter(@countries.first.name) }
      search_areas_path(filters)
    end
  end

  def location_filter(country_name)
    { location: { type: 'country', options: [country_name] } }
  end
end
