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

  before_action :load_cms_content

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
    overlays(['oecm', 'marine_wdpa'])
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
    @protectedAreasGrowth = [
      {
        id: "Global",
        datapoints: [
          { x: 2000, y: 0.67 },
          { x: 2001, y: 0.73 },
          { x: 2002, y: 0.99 },
          { x: 2003, y: 1.00 },
          { x: 2004, y: 1.11 },
          { x: 2005, y: 1.13 },
          { x: 2006, y: 1.05 },
          { x: 2007, y: 1.43 },
          { x: 2008, y: 1.85 },
          { x: 2009, y: 2.32 },
          { x: 2010, y: 2.50 },
          { x: 2011, y: 2.53 },
          { x: 2012, y: 3.38 },
          { x: 2013, y: 3.47 },
          { x: 2014, y: 4.15 },
          { x: 2015, y: 4.43 },
          { x: 2016, y: 5.01 },
          { x: 2017, y: 6.4 }
        ]
      },
      {
        id: "National",
        datapoints: [
          { x: 2000, y: 1.72 },
          { x: 2001, y: 1.88 },
          { x: 2002, y: 2.54 },
          { x: 2003, y: 2.57 },
          { x: 2004, y: 2.86 },
          { x: 2005, y: 2.89 },
          { x: 2006, y: 2.70 },
          { x: 2007, y: 3.68 },
          { x: 2008, y: 3.93 },
          { x: 2009, y: 5.13 },
          { x: 2010, y: 5.88 },
          { x: 2011, y: 5.94 },
          { x: 2012, y: 8.43 },
          { x: 2013, y: 8.65 },
          { x: 2014, y: 9.66 },
          { x: 2015, y: 10.36 },
          { x: 2016, y: 12.74 },
          { x: 2017, y: 16.02 }
        ]
      },
      {
        id: "ABNJ",
        datapoints: [
          { x: 2000, y: 0.00 },
          { x: 2001, y: 0.00 },
          { x: 2002, y: 0.00 },
          { x: 2003, y: 0.00 },
          { x: 2004, y: 0.00 },
          { x: 2005, y: 0.00 },
          { x: 2006, y: 0.00 },
          { x: 2007, y: 0.00 },
          { x: 2008, y: 0.00 },
          { x: 2009, y: 0.00 },
          { x: 2010, y: 0.17 },
          { x: 2011, y: 0.17 },
          { x: 2012, y: 0.17 },
          { x: 2013, y: 0.17 },
          { x: 2014, y: 0.25 },
          { x: 2015, y: 0.25 },
          { x: 2016, y: 0.25 },
          { x: 2017, y: 1.18 }
        ]
      }
    ].to_json
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
