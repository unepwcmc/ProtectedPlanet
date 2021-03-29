class HomeController < ApplicationController
  include MapHelper

  def index
    @pa_coverage_percentage = home_presenter.pas_coverage_percentage

    @config_search_areas = {
      id: 'all',
      placeholder: I18n.t('global.placeholder.search-oecm-wdpa')
    }.to_json

    @pas_title = home_yml[:pas][:title]
    @pas_button = home_yml[:pas][:button]
    @pas_link = search_areas_path(geo_type: 'site')
    @pas_levels = levels

    @site_facts = home_presenter.fact_card_stats
    @update_date = home_presenter.update_date

    comfy_themes = Comfy::Cms::Page.find_by_slug("thematic-areas")
    @themes_title = comfy_themes.label
    @themes_url = comfy_themes.full_path

    @regions_page = Comfy::Cms::Page.find_by_slug("unep-regions")

    @carousel_slides = HomeCarouselSlide.all.select{|slide| slide.published }

    @main_map = {
      overlays: MapOverlaysSerializer.new(home_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'all',
      point_query_services: all_services_for_point_query
    }
  end

  private

  def home_overlays
    overlays(['oecm', 'marine_wdpa', 'terrestrial_wdpa'])
  end

  private

  def levels
    _levels = home_yml[:pas][:levels]
    _levels.map do |level|
      level[:url] = search_areas_path(geo_type: level[:geo_type])
      level
    end
  end

  def home_yml
    @home_yml ||= I18n.t('home')
  end

  def home_presenter 
    @presenter ||= HomePresenter.new
  end
end