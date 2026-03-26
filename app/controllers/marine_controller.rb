class MarineController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include MapHelper

  def index
    marine_total_pas_count
    marine_statistics
    maine_protected_areas_growth
    marine_stats_items
    top_regions_countries_with_most_marine_protected_areas
    num_of_marine_protected_areas
    
    @view_all_marine_pas_url = search_areas_path(filters: SearchAreaLinkFilters.is_type_marine_filters)
    # Removed mpa_map from ['csv', 'shp', 'gdb', 'map_map'] in feat/hide-mpa-download-button
    @download_options = helpers.download_options(['csv', 'shp', 'gdb'], 'general', 'marine')


    @map = {
      overlays: MapOverlaysSerializer.new(marine_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'marine',
      point_query_services: marine_services_for_point_query
    }
    @filters = SearchAreaLinkFilters.wdpa_and_marine_is_true_filters
  end

  private


  def marine_data_cache_version
    @marine_data_cache_version ||= (ProtectedArea.maximum(:updated_at)&.to_i || 0)
  end

  def global_stats_cache_version
    @global_stats_cache_version ||= (GlobalStatistic.maximum(:updated_at)&.to_i || 0)
  end

  def num_of_marine_protected_areas
    @num_of_marine_protected_areas ||= ProtectedArea.marine_areas.limit(3)
  end

  def marine_total_pas_count
    @marine_total_pas_count ||= Rails.cache.fetch(
      "marine/marine_total_pas_count/#{marine_data_cache_version}",
      expires_in: 12.days
    ) { number_with_delimiter(ProtectedArea.marine_areas.count()) }
  end

  def marine_statistics
    @marine_statistics ||= Rails.cache.fetch(
      "marine/statistics/#{global_stats_cache_version}",
      expires_in: 12.days
    ) { GlobalStatistic.marine_stats }
  end

  def maine_protected_areas_growth
    @marine_protected_areas_growth ||= Rails.cache.fetch(
      "marine/maine_protected_areas_growth",
      expires_in: 12.days
    ) {
        {
          # x = x axis
          # 1, 2, 3 = series on the chart and also make the y axis
          datapoints: [
            { "x": Time.new(2000, 1, 1), "1": 2526266, "2": 0, "3": 2526266 },
            { "x": Time.new(2001, 1, 1), "1": 2723044, "2": 0, "3": 2723044 },
            { "x": Time.new(2002, 1, 1), "1": 2845701, "2": 0, "3": 2845701 },
            { "x": Time.new(2003, 1, 1), "1": 2878904, "2": 0, "3": 2878904 },
            { "x": Time.new(2004, 1, 1), "1": 2980729, "2": 0, "3": 2980729 },
            { "x": Time.new(2005, 1, 1), "1": 3079037, "2": 0, "3": 3079037 },
            { "x": Time.new(2006, 1, 1), "1": 6670152, "2": 0, "3": 6670152 },
            { "x": Time.new(2007, 1, 1), "1": 7835671, "2": 0, "3": 7835671 },
            { "x": Time.new(2008, 1, 1), "1": 7916368, "2": 0, "3": 7916368 },
            { "x": Time.new(2009, 1, 1), "1": 9583472, "2": 0, "3": 9583472 },
            { "x": Time.new(2010, 1, 1), "1": 10649529, "2": 380819, "3": 11030348 },
            { "x": Time.new(2011, 1, 1), "1": 10713142, "2": 380819, "3": 11093961 },
            { "x": Time.new(2012, 1, 1), "1": 12409801, "2": 558231, "3": 12968032 },
            { "x": Time.new(2013, 1, 1), "1": 12641722, "2": 558231, "3": 13199953 },
            { "x": Time.new(2014, 1, 1), "1": 14053366, "2": 558231, "3": 14611597 },
            { "x": Time.new(2015, 1, 1), "1": 15085513, "2": 558231, "3": 15643744 },
            { "x": Time.new(2016, 1, 1), "1": 16938756, "2": 558231, "3": 17496987 },
            { "x": Time.new(2017, 1, 1), "1": 19363517, "2": 2608187, "3": 21971704 },
            { "x": Time.new(2018, 1, 1), "1": 23665971, "2": 2608187, "3": 26274158 },
            { "x": Time.new(2019, 1, 1), "1": 24360959, "2": 2608187, "3": 26969146 },
            { "x": Time.new(2020, 1, 1), "1": 24360975, "2": 2608187, "3": 26969162 }
          ],
          units: "km2",
          legend: ["National", "ABNJ", "Global"]
        }.to_json
      }
  end

  def marine_stats_items
    @marine_stats_items ||= Rails.cache.fetch(
      "marine/marine_stats_items/#{I18n.locale}/#{global_stats_cache_version}",
      expires_in: 12.days
    ) do
      [
        {
          total: marine_statistics['total_ocean_pa_coverage_percentage'],
          text: t('thematic_area.marine.hero.stat_text_1'),
          decimal: 2,
          suffix: '%',
          small_number: true
        },
        {
          total: marine_statistics['total_marine_protected_areas'],
          text: t('thematic_area.marine.hero.stat_text_2'),
          decimal: 0,
          small_number: true
        },
        {
          total: marine_statistics['total_ocean_oecms_pas_coverage_percentage'].to_f - @marine_statistics['total_ocean_pa_coverage_percentage'].to_f,
          text: t('thematic_area.marine.hero.stat_text_3'),
          decimal: 2,
          suffix: '%',
          small_number: true
        },
        {
          total: marine_statistics['total_marine_oecms_pas'].to_i - @marine_statistics['total_marine_protected_areas'].to_i,
          text: t('thematic_area.marine.hero.stat_text_4'),
          decimal: 0,
          small_number: true
        },
        {
          total: marine_statistics['total_ocean_oecms_pas_coverage_percentage'],
          text: t('thematic_area.marine.hero.stat_text_5'),
          decimal: 2,
          suffix: '%',
          small_number: true
        },
        {
          total: marine_statistics['total_ocean_area_oecms_pas'],
          text: t('thematic_area.marine.hero.stat_text_6'),
          decimal: 0,
          suffix: 'km<sup>2</sup>',
          small_number: true
        }
      ]
    end
  end

  def top_regions_countries_with_most_marine_protected_areas
    @top_regions_countries_with_most_marine_protected_areas ||= Rails.cache.fetch(
      "marine/regions_top_countries/#{marine_data_cache_version}",
      expires_in: 12.days
    ) do
      Region.without_global.map do |region|
        RegionPresenter.new(region).top_marine_coverage_countries
      end.to_json
    end
  end

  def marine_overlays
    overlays(['oecm_marine', 'marine_wdpa'], {
      marine_wdpa: {
        isShownByDefault: true
      }
    })
  end
end
