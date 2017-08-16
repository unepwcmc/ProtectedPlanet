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
      }
    ]
  end
end
