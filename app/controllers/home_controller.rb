class HomeController < ApplicationController
  include MapHelper

  def index
    @pa_coverage_percentage = home_presenter.pas_coverage_percentage

    @config_search_areas = {
      id: 'all',
      placeholder: I18n.t('global.placeholder.search-wdpca')
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

    @main_map = all_areas_map_config
  end

  private

  def levels
    levels_config = home_yml[:pas][:levels]
    levels_config.map do |level|
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