class MarineController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include MapHelper

  #Static stats
  before_action :marine_statistics, only: [:index, :download_designations]
  before_action :maine_protected_areas_growth, only: [:index]
  before_action :ecoregions, only: [:index]
  before_action :pledges, only: [:index]
  before_action :marine_stats_items, only: [:index]

  #Calculated stats
  before_action :coverage
  before_action :most_protected_areas, only: [:index]
  before_action :national_statistics, only: [:index]
  before_action :designations, only: [:index, :download_designations]


  def index
    @marineSites = ProtectedArea.marine_areas.limit(3) ## FERDI 3 marine PAs
    @marineSitesTotal = number_with_delimiter(ProtectedArea.marine_areas.count())
    @marineViewAllUrl = search_areas_path(filters: SearchAreaLinkFilters.is_type_marine_filters)

    # Removed mpa_map from ['csv', 'shp', 'gdb', 'map_map'] in feat/hide-mpa-download-button
    @download_options = helpers.download_options(['csv', 'shp', 'gdb'], 'general', 'marine')

    @regionCoverage = Region.without_global.map do |region|
      RegionPresenter.new(region).marine_coverage
    end

    @pas_km = @marine_statistics['total_ocean_area_protected']
    @pas_percent = @marine_statistics['total_ocean_pa_coverage_percentage']
    @pas_total = @marine_statistics['total_marine_protected_areas']
    @map = {
      overlays: MapOverlaysSerializer.new(marine_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'marine',
      point_query_services: marine_services_for_point_query
    }
    @filters = SearchAreaLinkFilters.wdpa_and_marine_is_true_filters
  end

  # Remove, it is not used
  def download_designations
    send_data(
      generate_designations_csv,
      filename: "most_recent_designations.csv",
      type: "text/csv"
    )
  end

  private

  def marine_overlays
    overlays(['oecm_marine', 'marine_wdpa'], {
      marine_wdpa: {
        isShownByDefault: true
      }
    })
  end

  # Remove, it is not used
  def generate_designations_csv
    columns = ["PA name", "Country", "Size", "Date of designation"]
    CSV.generate(headers: true) do |csv|
      csv << columns
      @designations.each do |d|
        csv << d.values
      end
    end
  end

  def coverage
    @coverageOfTop20ProtectedAreas = [
      {
        title: "Total global coverage of all MPAs",
        km: @marine_statistics["national_waters_pa_coverage_area"].to_i + @marine_statistics["high_seas_pa_coverage_area"].to_i
      },
      {
        title: "Total global coverage of largest 20 MPAs",
        km: 17573997
        #Need to fix calculation for most protected marine areas. For some of those we need to sum the area of their PIDs
        #km: ProtectedArea.sum_of_most_protected_marine_areas
      }
    ].to_json
  end

  def most_protected_areas
    @regionsTopCountries = Rails.cache.fetch(
      "marine/regions_top_countries/#{marine_data_cache_version}",
      expires_in: 12.days
    ) do
      Region.without_global.map do |region|
        RegionPresenter.new(region).top_marine_coverage_countries
      end.to_json
    end
  end

  # Remove, it is not used
  def least_protected_areas
    ProtectedArea.least_protected_marine_areas(20).map do |pa|
      ProtectedAreaPresenter.new(pa).name_size
    end
  end

  # Remove, it is not used
  def national_statistics
    ## TODO it should take into account ABNJ as well
    @top_marine_coverage_countries = {
      name: "ocean areas",
      children:
        CountryStatistic.top_marine_coverage.map do |country_statistic|
          ## TODO if country is nil check if that corresponds to ABNJ
          CountryPresenter.new(country_statistic.country).marine_page_statistics
        end
    }
  end

  # Remove, it is not used
  def designations
    @designations = Rails.cache.fetch(
      "marine/designations/#{marine_data_cache_version}",
      expires_in: 6.hours
    ) do
      protected_areas = ProtectedArea.most_recent_designations(10)
      protected_areas.map do |pa|
        ProtectedAreaPresenter.new(pa).marine_designation
      end
    end
  end

  def marine_statistics
    @marine_statistics = Rails.cache.fetch(
      "marine/statistics/#{global_stats_cache_version}",
      expires_in: 12.days
    ) { GlobalStatistic.marine_stats }
  end

  def marine_stats_items
    @marine_stats_items = Rails.cache.fetch(
      "marine/stats_items/#{I18n.locale}/#{global_stats_cache_version}",
      expires_in: 12.days
    ) do
      [
        {
          total: @marine_statistics['total_ocean_pa_coverage_percentage'],
          text: t('thematic_area.marine.hero.stat_text_1'),
          decimal: 2,
          suffix: '%',
          small_number: true
        },
        {
          total: @marine_statistics['total_marine_protected_areas'],
          text: t('thematic_area.marine.hero.stat_text_2'),
          decimal: 0,
          small_number: true
        },
        {
          total: @marine_statistics['total_ocean_oecms_pas_coverage_percentage'].to_f - @marine_statistics['total_ocean_pa_coverage_percentage'].to_f,
          text: t('thematic_area.marine.hero.stat_text_3'),
          decimal: 2,
          suffix: '%',
          small_number: true
        },
        {
          total: @marine_statistics['total_marine_oecms_pas'].to_i - @marine_statistics['total_marine_protected_areas'].to_i,
          text: t('thematic_area.marine.hero.stat_text_4'),
          decimal: 0,
          small_number: true
        },
        {
          total: @marine_statistics['total_ocean_oecms_pas_coverage_percentage'],
          text: t('thematic_area.marine.hero.stat_text_5'),
          decimal: 2,
          suffix: '%',
          small_number: true
        },
        {
          total: @marine_statistics['total_ocean_area_oecms_pas'],
          text: t('thematic_area.marine.hero.stat_text_6'),
          decimal: 0,
          suffix: 'km<sup>2</sup>',
          small_number: true
        }
      ]
    end
  end

  def marine_data_cache_version
    @marine_data_cache_version ||= (ProtectedArea.maximum(:updated_at)&.to_i || 0)
  end

  def global_stats_cache_version
    @global_stats_cache_version ||= (GlobalStatistic.maximum(:updated_at)&.to_i || 0)
  end

  def maine_protected_areas_growth
    @marine_protected_areas_growth = {
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
  end

  # Remove, it is not used
  def ecoregions
    @mostProtectedEcoregions = [
      {
        name: "Galapagos",
        value: 100
      },
      {
        name: "Amsterdam-St Paul",
        value: 100
      },
      {
        name: "Subantarctic Islands",
        value: 95.5
      }
    ].to_json

    @leastProtectedEcoregions = [
      {
        name: "West and South Indian Shelf",
        value: 0.95
      },
      {
        name: "Marquesas",
        value: 0.89
      },
      {
        name: "Continental High Antarctic",
        value: 0.04
      }
    ].to_json

  end

  # Remove, it is not used
  def pledges
    @pledges = {
      name: "protected areas",
      children: [
        {
          name: "National priority actions",
          size: 478520,
          breakdown: [
            {
              name: "National Waters",
              size: 478520
            }
          ]
        },
        {
          name: "Approved GEF-5 and GEF-6 projects",
          size: 762246,
          breakdown: [
            {
              name: "National Waters",
              size: 762246
            }
          ]
        },
        {
          name: "Voluntary commitments from UN Ocean Conference",
          size: 17635796,
          breakdown: [
            {
              name: "National Waters",
              size: 14035796
            },
            {
              name: "ABNJ",
              size: 3600000
            }
          ]
        },
        {
          name: "Other Large MPA proposals",
          size: 3822552,
          breakdown: [
            {
              name: "National Waters",
              size: 2272552
            },
            {
              name: "ABNJ",
              size: 1550000
            }
          ]
        },
        {
          name: "Micronesia and Caribbean Challenge",
          size: 502083,
          breakdown: [
            {
              name: "National Waters",
              size: 502083
            }
          ]
        },
        {
          name: "Protected area targets in post-COP10 NBSAPs",
          size: 3587340,
          breakdown: [
            {
              name: "National Waters",
              size: 3587340
            }
          ]
        }
      ]
    }.to_json
  end
end
