class ProtectedAreasController < ApplicationController
  after_action :record_visit
  after_action :enable_caching
  include MapHelper

  def show
    id = params[:id]
    @protected_area = ProtectedArea.
      where("slug = ? OR wdpa_id = ?", id, id.to_i).
      first

    @protected_area or raise_404

    @presenter = ProtectedAreaPresenter.new @protected_area
    @countries = @protected_area.countries.without_geometry
    @other_designations = load_other_designations
    # @networks = load_networks

    @wikipedia_article = @protected_area.try(:wikipedia_article)

    @locations = get_locations

    # @protected_area.sources
    @sources = [
      {
        title: 'Source name',
        date_updated: '2019',
        url: 'http://link-to-source.com'
      }
    ]

    @wdpa_other = get_other_sites


    @otherWdpasViewAllUrl = determine_search_path(@protected_area)
  

    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize
    }

    @map_options = {
      map: { 
        boundsUrl: @protected_area.extent_url
      }
    }

    helpers.opengraph_title_and_description_with_suffix(@protected_area.name)

    respond_to do |format|
      format.html
      format.pdf {
        rasterizer = Rails.root.join("vendor/assets/javascripts/rasterize.js")
        url = url_for(action: :show, id: @protected_area.wdpa_id, for_pdf: true)
        dest_pdf = Rails.root.join("tmp/#{@protected_area.wdpa_id}-site.pdf").to_s

        `phantomjs #{rasterizer} '#{url}' #{dest_pdf} A4`
        send_file dest_pdf, type: 'application/pdf'
      }
    end
  end

  private

  def map_overlays
    overlays(['individual_site'], {
      individual_site: @protected_area.arcgis_layer_config
    })
  end

  def get_locations
    locations = []
    
    if @countries.any?
      @countries.each_with_index do |country, i|
        locations << ActionController::Base.helpers.link_to(country.name, country_path(country.iso))
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

  # TODO: Methods, models, controllers, modules related to Networks are slated for removal

  # TRANSBOUNDARY_SITES = "Transboundary sites".freeze
  # def load_networks
  #   networks = @protected_area.networks.reject(&:designation)
  #   # ensure that transboundary sites network always appears first
  #   networks.sort { |a,b| a.name == TRANSBOUNDARY_SITES ? -1 : a.name <=> b.name }
  # end

  def get_other_sites
    return ProtectedArea.all_except(@protected_area).take(3) if @countries.length <= 1
    ProtectedArea.all_except(@protected_area).transboundary_sites.take(3)
  end

  def determine_search_path(area)
    if area.is_transboundary
      search_areas_path(filters: { special_status: ['is_transboundary'] })
    else
      search_areas_path(filters: { location: { type: 'site', options: ["#{@countries.first.name}"] } })
    end
  end
end
