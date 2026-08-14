class HomeController < ApplicationController
  include MapHelper

  def index
    @config_search_areas = {
      id: 'all',
      placeholder: I18n.t('global.placeholder.search-wdpca')
    }

    @pas_title = home_yml[:pas][:title]
    @pas_button = home_yml[:pas][:button]
    @pas_link = search_areas_path(geo_type: 'site')
    @pas_levels = levels

    @site_facts = home_presenter.fact_card_stats
    @update_date = home_presenter.update_date

    @carousel_slides = HomeCarouselSlide.all.select { |slide| slide.published }

    @main_map = {
      overlays: MapOverlaysSerializer.new(home_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'all',
      point_query_services: all_services_for_point_query,
      popup_attributes: map_yml[:popup_attributes],
      disclaimer: map_yml[:disclaimer]
    }
  end

  private

  def home_overlays
    overlays(%w[oecm marine_wdpa terrestrial_wdpa])
  end

  def levels
    _levels = home_yml[:pas][:levels]
    # I18n.t returns frozen translation hashes, so build a new hash rather than
    # mutating the level in place (raises FrozenError otherwise).
    _levels.map do |level|
      level.merge(url: search_areas_path(geo_type: level[:geo_type]))
    end
  end

  def home_yml
    @home_yml ||= I18n.t('home')
  end

  def home_presenter
    @presenter ||= HomePresenter.new
  end
end
