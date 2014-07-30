namespace :stats do
  desc "Calculates geospatial statistics"
  task calculate: :environment do

    populator = Geospatial::CountryGeometryPopulator
    populator.repair_geometries
    Country.select(:iso_3).order(:iso_3).each do |country|
      populator.populate_dissolved_geometries country
      populator.populate_marine_geometries country
    end

    Geospatial::Calculator.calculate_statistics
  end
end
