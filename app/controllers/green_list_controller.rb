class GreenListController < ApplicationController
  include MapHelper
  # Show page for green listed protected areas
  # Will only show if that area is a green listed area, otherwise redirects to wdpa page
  # before_action :find_protected_area
  before_action :most_protected_areas, only: [:index]
  before_action :get_green_list_sites, only: [:index, :show]
  # before_action :redirect_if_not_green_listed
  # after_action :record_visit
  # after_action :enable_caching

  def index
    @download_options = helpers.download_options(['csv', 'shp', 'gdb'], 'general', 'greenlist')

    # TODO - statistics are not accurate
    stats = green_list_statistics
    @pas_km = stats['green_list_area']
    @pas_percent = stats['green_list_perc']
    @pas_total = stats['green_list_count']

    # Starts from 2000
    @protectedAreaGrowth = 
    {
      title: I18n.t('charts.legend.number-pa'),
      units: I18n.t('charts.units.km2'),
      datapoints: ProtectedArea.greenlist_coverage_growth(2000).map { |el| { year: el[0], value: el[1] } }
    }.to_json 
    
    # TODO - This may need to be reworked by CLS
    @total_area_percent = Stats::Global.percentage_pa_cover.to_f - @pas_percent.to_f

    @filters = {
      db_type: ['wdpa'],
      special_status: ['is_green_list']
    }

    @greenListViewAllUrl = search_areas_path(filters: { special_status: ['is_green_list']} )

    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'is_green_list'
    }
  end

  def show
    @presenter = ProtectedAreaPresenter.new @protected_area
    @countries = @protected_area.countries.without_geometry
    @other_designations = []
    @networks = []

    @wikipedia_article = @protected_area.try(:wikipedia_article)

    @greenListViewAllUrl = search_areas_path(filters: { special_status: ['is_green_list']} )
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

  def most_protected_areas
    @regionsTopCountries = Region.without_global.map do |region|
      top_countries = RegionPresenter.new(region).top_gl_coverage_countries
      
      if region.countries.count < 10
        # Always return an array 10 items
        top_countries[:countries] = top_countries[:countries].in_groups_of(10, {}).flatten
      end

      top_countries
    end.compact.to_json
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

  def get_green_list_sites
    @example_greenlist ||= green_list_areas.take(3)
  end
  
  def green_list_areas
    @green_list_areas ||= ProtectedArea.green_list_areas
  end
end
