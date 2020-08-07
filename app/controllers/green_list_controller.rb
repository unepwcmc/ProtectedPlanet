class GreenListController < ApplicationController
  include MapHelper
  # Show page for green listed protected areas
  # Will only show if that area is a green listed area, otherwise redirects to wdpa page
  # before_action :find_protected_area
  # before_action :redirect_if_not_green_listed
  # after_action :record_visit
  # after_action :enable_caching

  def index
    stats = green_list_statistics
    @pas_km = stats['green_list_area']
    @pas_percent = stats['green_list_perc']
    @pas_total = stats['green_list_count']

    @protectedAreaGrowth = [
      {
        id: "Global",
        datapoints: [
          { x: 2000, y: 0.67 }
        ]
      },
      {
        id: "National",
        datapoints: [
          { x: 2000, y: 0.67 }
        ]
      },
      {
        id: "ABNJ",
        datapoints: [
          { x: 2000, y: 0.67 }
        ]
      }
    ].to_json ##TODO See marine page for example - data needed from CLS

    @regionsTopCountries = [] ##TODO See marine page for example

    @total_area_percent = Stats::Global.percentage_pa_cover 


    @filters = {
      db_type: ['wdpa'],
      special_status: ['is_green_list']
    }

    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize
    }
  end

  def show
    @presenter = ProtectedAreaPresenter.new @protected_area
    @countries = @protected_area.countries.without_geometry
    @other_designations = []
    @networks = []

    @wikipedia_article = @protected_area.try(:wikipedia_article)
  end

  def record_visit
    return if @protected_area.nil?

    year_month = DateTime.now.strftime("%m-%Y")
    $redis.zincrby(year_month, 1, @protected_area.wdpa_id)
  end

  private

  def green_list_statistics
    @green_list_statistics ||= $redis.hgetall('green_list_stats')
  end

  def map_overlays
    overlays(['greenlist'], {
      greenlist: {
        queryString: greenlist_query_string(green_list_areas.map(&:id))
      }
    })
  end

  def redirect_if_not_green_listed
    redirect_to protected_area_path(@protected_area) unless @protected_area.is_green_list
  end

  def find_protected_area
    id = params[:id]
    @protected_area = ProtectedArea.
      where("slug = ? OR wdpa_id = ?", id, id.to_i).
      first

    @protected_area or raise_404
  end

  def green_list_areas
    @green_list_areas ||= ProtectedArea.green_list_areas
  end
end
