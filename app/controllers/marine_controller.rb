class MarineController < ApplicationController
  
  def index
    # coverage
    @totalMarineProtectedAreas = 18300
    @oceanProtectedAreasPercent = 5.7
    @oceanProtectedAreasKm = 20500000

    # distribution
    @distributions = {
      nationalWaters: 39,
      nationalWatersPa: 15.9,
      nationalWatersKm: 10106820,
      highSeas: 61,
      highSeasPa: 0.4,
      highSeasKm: 500000
    }

    # growth
    protectedAreasGrowth = [
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
    ]

    @protectedAreasGrowth = protectedAreasGrowth.to_json

    # national
    nationalProtectedAreas = {
      name: "ocean areas",
      children: [
        {
          name: "Australia",
          totalMarineArea: 7432133,
          totalOverseasTerritories: 9,
          national: 3021418,
          nationalPercentage: 40.65,
          overseas: 4410704,
          overseasPercentage: 28.72
        },
        {
          name: "United Kingdom",
          totalMarineArea: 7654321,
          totalOverseasTerritories: 5,
          national: 12340,
          nationalPercentage: 12345,
          overseas: 9234,
          overseasPercentage: 5432
        },
        {
          name: "USA",
          totalMarineArea: 6543211,
          totalOverseasTerritories: 1,
          national: 12342,
          nationalPercentage: 12,
          overseas: 12344,
          overseasPercentage: 50
        },
        {
          name: "France",
          totalMarineArea: 5432111,
          totalOverseasTerritories: 1,
          national: 1232,
          nationalPercentage: 21,
          overseas: 1123123,
          overseasPercentage: 30
        }
      ]
    }

    @nationalProtectedAreas = nationalProtectedAreas.to_json

    # size distribution
    top20ProtectedAreas = [
      {
        name: "Ross Sea Marine Reserve",
        km: 1550000
      },
      {
        name: "Papahānaumokuākea Marine National Monument",
        km: 1510000
      },
      {
        name: "Natural Park of the Coral Sea",
        km: 1292967
      },
      {
        name: "Marianas Trench Marine National Monument",
        km: 345400
      }
    ]

    @top20ProtectedAreas = top20ProtectedAreas.to_json

    coverageOfTop20ProtectedAreas = [
      {
        title: "Total global coverage of all MPA’s",
        km: 20500000
      },
      {
        title: "Total global coverage of largest 20 MPA’s",
        km: 15000000
      }
    ]

    @coverageOfTop20ProtectedAreas = coverageOfTop20ProtectedAreas.to_json

    # ecoregions
    mostProtectedEcoregions = [
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
    ]

    @mostProtectedEcoregions = mostProtectedEcoregions.to_json

    leastProtectedEcoregions = [
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
    ]

    @leastProtectedEcoregions = leastProtectedEcoregions.to_json

    # pledges
    pledges = {
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
    }

    @pledges = pledges.to_json

    # designations
    @designations = [
      {
        name: "Northern Bering Sea",
        country: "United States of America",
        size: "2,105,050km²",
        date: "2016"
      },
      {
        name: "Natural Park of the Coral Sea",
        country: "United Kingdom of Great Britain",
        size: "15,694km²",
        date: "2016"
      },
      {
        name: "New Caledonia",
        country: "United States of America",
        size: "1,292,967km²",
        date: "2017"
      }
    ]

    # greenlist
    # ??
  end
end
