class MarineController < ApplicationController

  #Static stats
  before_action :total_coverage, only: [:index]
  before_action :distributions, only: [:index]
  before_action :growth, only: [:index]
  before_action :ecoregions, only: [:index]
  before_action :pledges, only: [:index]

  #Calculated stats
  before_action :coverage
  before_action :most_protected_areas, only: [:index]
  before_action :national_statistics, only: [:index]
  before_action :designations, only: [:index]
  before_action :green_list_areas, only: [:index]

  COUNTRIES = [
    "United States of America",
    "France",
    "Australia",
    "United Kingdom of Great Britain and Northern Ireland",
    "New Zealand",
    "Denmark",
    "Norway",
    "Netherlands"
  ]

  def index
  end

  def coverage
    @coverageOfTop20ProtectedAreas = [
      {
        title: "Total global coverage of all MPA’s",
        km: @distributions[:nationalWatersKm] + @distributions[:highSeasKm]
      },
      {
        title: "Total global coverage of largest 20 MPA’s",
        km: ProtectedArea.sum_of_most_protected_marine_areas
      }
    ].to_json
  end

  def most_protected_areas
    @top10ProtectedAreas =
      ProtectedArea.most_protected_marine_areas(10).map do |pa|
        ProtectedAreaPresenter.new(pa).name_size
      end.to_json
  end

  def least_protected_areas
    ProtectedArea.least_protected_marine_areas(20).map do |pa|
      ProtectedAreaPresenter.new(pa).name_size
    end
  end

  def national_statistics
    @nationalProtectedAreas = {
      name: "ocean areas",
      children:
        Country.where(name: COUNTRIES).map do |country|
          CountryPresenter.new(country).marine_statistics
        end
    }.to_json
  end

  def designations
    protected_areas = ProtectedArea.most_recent_designations(10)
    @designations = protected_areas.map do |pa|
      ProtectedAreaPresenter.new(pa).marine_designation
    end
  end

  def total_coverage
    @totalMarineProtectedAreas = 15271
    @oceanProtectedAreasPercent = 6.35
    @oceanProtectedAreasKm = 23036078
  end

  def distributions
    @distributions = {
      nationalWaters: 39,
      nationalWatersPa: 15.9,
      nationalWatersKm: 22445068,
      highSeas: 61,
      highSeasPa: 0.25,
      highSeasKm: 558116
    }
  end

  def growth
    @protectedAreasGrowth = [
      {
        id: "Global",
        dataset: [
          {
            year: 2000,
            percent: 0.67
          },
          {
            year: 2001,
            percent: 0.73
          },
          {
            year: 2002,
            percent: 0.99
          },
          {
            year: 2003,
            percent: 1.00
          },
          {
            year: 2004,
            percent: 1.11
          },
          {
            year: 2005,
            percent: 1.13
          },
          {
            year: 2006,
            percent: 1.05
          },
          {
            year: 2007,
            percent: 1.43
          },
          {
            year: 2008,
            percent: 1.85
          },
          {
            year: 2009,
            percent: 2.32
          },
          {
            year: 2010,
            percent: 2.50
          },
          {
            year: 2011,
            percent: 2.53
          },
          {
            year: 2012,
            percent: 3.38
          },
          {
            year: 2013,
            percent: 3.47
          },
          {
            year: 2014,
            percent: 4.15
          },
          {
            year: 2015,
            percent: 4.43
          },
          {
            year: 2016,
            percent: 5.01
          },
          {
            year: 2017,
            percent: 6.35
          }
        ]
      },
      {
        id: "National",
        dataset: [
          {
            year: 2000,
            percent: 1.72
          },
          {
            year: 2001,
            percent: 1.88
          },
          {
            year: 2002,
            percent: 2.54
          },
          {
            year: 2003,
            percent: 2.57
          },
          {
            year: 2004,
            percent: 2.86
          },
          {
            year: 2005,
            percent: 2.89
          },
          {
            year: 2006,
            percent: 2.70
          },
          {
            year: 2007,
            percent: 3.68
          },
          {
            year: 2008,
            percent: 3.93
          },
          {
            year: 2009,
            percent: 5.13
          },
          {
            year: 2010,
            percent: 5.88
          },
          {
            year: 2011,
            percent: 5.94
          },
          {
            year: 2012,
            percent: 8.43
          },
          {
            year: 2013,
            percent: 8.65
          },
          {
            year: 2014,
            percent: 9.66
          },
          {
            year: 2015,
            percent: 10.36
          },
          {
            year: 2016,
            percent: 12.74
          },
          {
            year: 2017,
            percent: 15.89
          }
        ]
      },
      {
        id: "ABNJ",
        dataset: [
          {
            year: 2000,
            percent: 0.00
          },
          {
            year: 2001,
            percent: 0.00
          },
          {
            year: 2002,
            percent: 0.00
          },
          {
            year: 2003,
            percent: 0.00
          },
          {
            year: 2004,
            percent: 0.00
          },
          {
            year: 2005,
            percent: 0.00
          },
          {
            year: 2006,
            percent: 0.00
          },
          {
            year: 2007,
            percent: 0.00
          },
          {
            year: 2008,
            percent: 0.00
          },
          {
            year: 2009,
            percent: 0.00
          },
          {
            year: 2010,
            percent: 0.17
          },
          {
            year: 2011,
            percent: 0.17
          },
          {
            year: 2012,
            percent: 0.17
          },
          {
            year: 2013,
            percent: 0.17
          },
          {
            year: 2014,
            percent: 0.25
          },
          {
            year: 2015,
            percent: 0.25
          },
          {
            year: 2016,
            percent: 0.25
          },
          {
            year: 2017,
            percent: 0.25
          }
        ]
      }
    ].to_json
  end

  def ecoregions
    @mostProtectedEcoregions = [
      {
        name: "Eastern Indo-Pacific",
        value: 24.3
      },
      {
        name: "Temperate Northern Pacific",
        value: 21
      },
      {
        name: "Temperate Australasia",
        value: 19
      }
    ].to_json

    @leastProtectedEcoregions = [
      {
        name: "Southern Cold Water",
        value: 5
      },
      {
        name: "Temperate South America",
        value: 4
      },
      {
        name: "Atlantic Warm Water",
        value: 3
      }
    ].to_json

  end

  def pledges
    @pledges = {
      name: "protected areas",
      children: [
        {
          name: "National priority actions",
          size: 353258,
          breakdown: [
            {
              name: "National Waters",
              size: 353258
            }
          ]
        },
        {
          name: "Approved GEF-5 and GEF-6 projects",
          size: 315439,
          breakdown: [
            {
              name: "National Waters",
              size: 315439
            }
          ]
        },
        {
          name: "Voluntary commitments from UN Ocean Conference",
          size: 9865824,
          breakdown: [
            {
              name: "National Waters",
              size: 8065824
            },
            {
              name: "ABNJ",
              size: 1800000
            }
          ]
        },
        {
          name: "Other Large MPA proposals",
          size: 3481409,
          breakdown: [
            {
              name: "National Waters",
              size: 353258
            },
            {
              name: "ABNJ",
              size: 1550000
            }
          ]
        },
        {
          name: "Micronesia and Caribbean Challenge",
          size: 272549,
          breakdown: [
            {
              name: "National Waters",
              size: 272549
            }
          ]
        },
        {
          name: "Protected area targets in post-COP10 NBSAPs",
          size: 2004710,
          breakdown: [
            {
              name: "National Waters",
              size: 2004710
            }
          ]
        }
      ]
    }.to_json
  end

  def green_list_areas
    @green_list_areas = ProtectedArea.marine_areas.green_list_areas
  end
end
