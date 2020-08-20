class MarineController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include MapHelper

  #Static stats
  before_action :marine_statistics, only: [:index, :download_designations]
  before_action :growth, only: [:index]
  before_action :ecoregions, only: [:index]
  before_action :pledges, only: [:index]

  #Calculated stats
  before_action :coverage
  before_action :most_protected_areas, only: [:index]
  before_action :national_statistics, only: [:index]
  before_action :designations, only: [:index, :download_designations]


  def index
    @marineSites = ProtectedArea.marine_areas.limit(3) ## FERDI 3 marine PAs
    @marineSitesTotal = number_with_delimiter(ProtectedArea.marine_areas.count())
    @marineViewAllUrl = '/' #TODO URL to filtered search results page

    @regionCoverage = Region.without_global.map do |region|
      RegionPresenter.new(region).marine_coverage
    end

    @pas_km = @marine_statistics['total_ocean_area_protected']
    @pas_percent = @marine_statistics['total_ocean_pa_coverage_percentage']
    @pas_total = @marine_statistics['total_marine_protected_areas']
    @map = {
      overlays: MapOverlaysSerializer.new(marine_overlays, map_yml).serialize
    }
    @filters = { db_type: ['wdpa'], is_marine: true }
  end

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
    @regionsTopCountries = Region.without_global.map do |region|
      RegionPresenter.new(region).top_marine_coverage_countries
    end.to_json
  end

  def least_protected_areas
    ProtectedArea.least_protected_marine_areas(20).map do |pa|
      ProtectedAreaPresenter.new(pa).name_size
    end
  end

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

  def designations
    protected_areas = ProtectedArea.most_recent_designations(10)
    @designations = protected_areas.map do |pa|
      ProtectedAreaPresenter.new(pa).marine_designation
    end
  end

  def marine_statistics
    @marine_statistics = $redis.hgetall('wdpa_marine_stats')
  end

  def growth
    @protectedAreasGrowth = {
      dataProvider: [
        {
          { year: 2000, "1": 0.67, "2": 1.72, "3": 0.00 },
          { year: 2001, "1": 0.73, "2": 1.88, "3": 0.00 },
          { year: 2002, "1": 0.99, "2": 2.54, "3": 0.00 },
          { year: 2003, "1": 1.00, "2": 2.57, "3": 0.00 },
          { year: 2004, "1": 1.11, "2": 2.86, "3": 0.00 },
          { year: 2005, "1": 1.13, "2": 2.89, "3": 0.00 },
          { year: 2006, "1": 1.05, "2": 2.70, "3": 0.00 },
          { year: 2007, "1": 1.43, "2": 3.68, "3": 0.00 },
          { year: 2008, "1": 1.85, "2": 3.93, "3": 0.00 },
          { year: 2009, "1": 2.32, "2": 5.13, "3": 0.00 },
          { year: 2010, "1": 2.50, "2": 5.88, "3": 0.17 },
          { year: 2011, "1": 2.53, "2": 5.94, "3": 0.17 },
          { year: 2012, "1": 3.38, "2": 8.43, "3": 0.17 },
          { year: 2013, "1": 3.47, "2": 8.65, "3": 0.17 },
          { year: 2014, "1": 4.15, "2": 9.66, "3": 0.25 },
          { year: 2015, "1": 4.43, "2": 10.36, "3": 0.25 },
          { year: 2016, "1": 5.01, "2": 12.74, "3": 0.25 },
          { year: 2017, "1": 6., "2": 16.02, "3": 1.18 }
        }
      ],
      graphs: [
        {
          title: "Global",
          type: "line",
          valueField: "1"
        },
        {
          title: "National",
          type: "line",
          valueField: "2"
        },
        {
          title: "ABNJ",
          type: "line",
          valueField: "3"
         }
      ]
    }.to_json
  end

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
