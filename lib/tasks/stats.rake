namespace :stats do
  desc "Calculates geospatial statistics"
  task calculate: :environment do
    Country.select(:iso_3).order(:iso_3).each do |country|
      populator = Geospatial::CountryGeometryPopulator
      populator.populate_dissolved_geometries country
      populator.populate_marine_geometries country
    end

    Geospatial::Calculator.calculate_statistics
  end
end
