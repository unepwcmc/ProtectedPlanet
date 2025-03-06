class ProtectedAreasController < ApplicationController
  after_action :record_visit
  after_action :enable_caching
  include MapHelper

  def show
    id = params[:id]
    raise_404 unless params[:format].nil?

    @download_options = helpers.download_options(['csv', 'shp', 'gdb', 'pdf'], 'protected_area', id)

    # If found by slug, redirect to search page
    # This is to overcome possible issues with PAs with same name/slug and different WDPA ID
    pa = ProtectedArea.find_by(slug: id)
    redirect_to search_areas_path(search_term: pa.name) and return if pa

    @protected_area = ProtectedArea.find_by(wdpa_id: id.to_i)
    @protected_area or raise_404

    @presenter = ProtectedAreaPresenter.new @protected_area
    @countries = @protected_area.countries.without_geometry
    @other_designations = load_other_designations
    # @networks = load_networks

    @wikipedia_article = @protected_area.try(:wikipedia_article)

    @locations = get_locations

    # In the format [{title: ..., year: ..., responsible_party: ... }, ...]
    @sources = @protected_area.sources_per_pa

    @wdpa_other = get_other_sites



    @otherWdpasViewAllUrl = determine_search_path(@protected_area)


    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize,
      point_query_services: point_query_services
    }

    @map_options = {
      map: {
        boundsUrl: @protected_area.extent_url,
        maxZoom: 0
      }
    }
    
    helpers.opengraph_title_and_description_with_suffix(@protected_area.name)
    respond_to do |format|
      format.html 
      # format.pdf {
      #   rasterizer = Rails.root.join("vendor/assets/javascripts/rasterize.js")
      #   url = url_for(action: :show, id: @protected_area.wdpa_id, for_pdf: true)
      #   dest_pdf = Rails.root.join("tmp/#{@protected_area.wdpa_id}-site.pdf").to_s
      #   byebug
      #   `phantomjs #{rasterizer} '#{url}' #{dest_pdf} A4`
        
      #   send_file dest_pdf, type: 'application/pdf'
      # }
    end
  end

  private

  def map_overlays
    overlays(['individual_site'], {
      individual_site: @protected_area.arcgis_layer_config
    })
  end

  def point_query_services
    all_services_for_point_query.map do |service|
      service.merge({
        queryString: wdpaid_where_query([@protected_area.wdpa_id])
      })
    end
  end

  def get_locations
    locations = []

    if @countries.any?
      @countries.each_with_index do |country, i|
        locations << ActionController::Base.helpers.link_to(country.name, country_path(country.iso_3))
      end
    else
      locations << 'Areas Beyond National Jurisdiction'
    end

    locations.join(', ')
  end

  def record_visit
    return if @protected_area.nil?

    year_month = DateTime.now.strftime("%m-%Y")
    $redis.zincrby(year_month, 1, @protected_area.wdpa_id)
  end

  def load_other_designations
    other_designations = @protected_area.networks.detect(&:designation).try(:protected_areas)

    other_designations = Array.wrap(other_designations)
    other_designations.reject { |pa| pa.id == @protected_area.id }
  end

  OTHER_SITES = 3.freeze
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
      search_areas_path(filters: { special_status: ['is_transboundary'] })
    else
      filters = @countries.empty? ? {} : { filters: location_filter(@countries.first.name) }
      search_areas_path(filters)
    end
  end

  def location_filter(country_name)
    { location: { type: 'country', options: [country_name] } }
  end
end
