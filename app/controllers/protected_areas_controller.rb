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
    @structured_data = place_structured_data

    respond_to do |format|
      format.html
    end
  end

  private

  def meta_description
    t('meta.protected_area.description', name: @protected_area.name)
  end

  # A protected area is a Place, not a WebSite -- which is what all of these pages
  # claimed to be. Only fields backed by data already loaded (or a single indexed
  # lookup) are included; a page nobody can describe is worse than a short one.
  def place_structured_data
    {
      '@context': 'https://schema.org',
      '@type': 'Place',
      name: @protected_area.name,
      # Omitted when it matches name, which it does for most sites -- repeating the
      # same string as an alternate name tells a consumer nothing.
      alternateName: alternate_name,
      description: meta_description,
      # canonical_url rather than protected_area_url: default_url_options appends
      # ?locale=en to any route without a :locale segment, and /:id has none, so the
      # helper would disagree with the <link rel="canonical"> on the same page.
      url: canonical_url,
      address: address_structured_data,
      geo: geo_structured_data,
      additionalProperty: place_properties
    }.compact
  end

  def alternate_name
    original_name = @protected_area.original_name.presence
    return if original_name.nil? || original_name == @protected_area.name

    original_name
  end

  def address_structured_data
    return if @countries.empty?

    {
      '@type': 'PostalAddress',
      addressCountry: @countries.map(&:iso_3)
    }
  end

  # the_geom_latitude/longitude are string columns on the record, so this costs no
  # query and no PostGIS call.
  def geo_structured_data
    latitude = @protected_area.the_geom_latitude
    longitude = @protected_area.the_geom_longitude
    return if latitude.blank? || longitude.blank?

    { '@type': 'GeoCoordinates', latitude: latitude, longitude: longitude }
  end

  def place_properties
    properties = {
      'WDPA ID' => @protected_area.site_id,
      'Designation' => @protected_area.designation&.name,
      'IUCN Management Category' => @protected_area.iucn_category&.name,
      'Reported area (km²)' => @protected_area.reported_area&.to_f&.round(2)
    }

    properties.filter_map do |name, value|
      next if value.blank?

      { '@type': 'PropertyValue', name: name, value: value }
    end.presence
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

  def record_visit
    return if @protected_area.nil?

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
