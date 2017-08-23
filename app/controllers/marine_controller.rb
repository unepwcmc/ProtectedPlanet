class MarineController < ApplicationController

  #Calculated stats
  before_action :coverage
  before_action :most_protected_areas, only: [:index]
  before_action :national_statistics, only: [:index]
  before_action :designations, only: [:index]

  #Static stats
  before_action :total_coverage, only: [:index]
  before_action :distributions, only: [:index]
  before_action :growth, only: [:index]
  before_action :ecoregions, only: [:index]
  before_action :pledges, only: [:index]

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
    # greenlist
    # ??
  end

  def coverage
    @coverageOfTop20ProtectedAreas = [
      {
        title: "Total global coverage of all MPA’s",
        km: ProtectedArea.global_marine_coverage
      },
      {
        title: "Total global coverage of largest 20 MPA’s",
        km: ProtectedArea.sum_of_most_protected_marine_areas
      }
    ].to_json
  end

  def most_protected_areas
    @top20ProtectedAreas =
      ProtectedArea.most_protected_marine_areas(20).map do |pa|
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
    protected_areas = ProtectedArea.most_recent_designations(20)
    @designations = protected_areas.map do |pa|
      ProtectedAreaPresenter.new(pa).marine_designation
    end
  end

  def total_coverage
    @totalMarineProtectedAreas = 18300
    @oceanProtectedAreasPercent = 5.7
    @oceanProtectedAreasKm = 20500000
  end

  def distributions
    @distributions = {
      nationalWaters: 39,
      nationalWatersPa: 15.9,
      nationalWatersKm: 10106820,
      highSeas: 61,
      highSeasPa: 0.4,
      highSeasKm: 500000
    }
  end

  def growth
    @protectedAreasGrowth = [
      {
        id: "national",
        dataset: [
          {
            year: 2000,
            percent: 10,
            km: 1234
          },
          {
            year: 2005,
            percent: 12,
            km: 12334
          },
          {
            year: 2010,
            percent: 13,
            km: 12324
          },
          {
            year: 2015,
            percent: 18,
            km: 16234
          },
          {
            year: 2020,
            percent: 26,
            km: 12324
          }
        ]
      },
      {
        id: "other",
        dataset: [
          {
            year: 2000,
            percent: 30,
            km: 71234
          },
          {
            year: 2005,
            percent: 45,
            km: 15234
          },
          {
            year: 2010,
            percent: 55,
            km: 12344
          },
          {
            year: 2015,
            percent: 56,
            km: 12234
          },
          {
            year: 2020,
            percent: 67,
            km: 12534
          }
        ]
      },
      {
        id: "last",
        dataset: [
          {
            year: 2000,
            percent: 100,
            km: 16234
          },
          {
            year: 2005,
            percent: 98,
            km: 12374
          },
          {
            year: 2010,
            percent: 23,
            km: 51234
          },
          {
            year: 2015,
            percent: 18,
            km: 14234
          },
          {
            year: 2020,
            percent: 16,
            km: 16234
          }
        ]
      }
    ].to_json
  end

  def ecoregions
    @mostProtectedEcoregions = [
      {
        name: "North European Seas",
        value: 200000
      },
      {
        name: "Warm Temperate Northwest Atlantic",
        value: 140000
      },
      {
        name: "Northeast Australian Shelf",
        value: 110000
      }
    ].to_json

    @leastProtectedEcoregions = [
      {
        name: "Tropical East Pacific",
        value: 114000
      },
      {
        name: "West and South  Indian Shelf",
        value: 90000
      },
      {
        name: "Tropical East Pacific 2",
        value: 75000
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
end
