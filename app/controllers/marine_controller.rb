class MarineController < ApplicationController
  
  def index
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

    @distributions = {
      nationalWaters: 39,
      nationalWatersPa: 15.9,
      nationalWatersKm: 10106820,
      highSeas: 61,
      highSeasPa: 0.4,
      highSeasKm: 500000
    }

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
  end
end
