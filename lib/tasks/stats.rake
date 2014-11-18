LOGGER ||= Logger.new STDOUT

namespace :stats do
  desc "Calculates geospatial statistics"
  task calculate: :environment do
    LOGGER.info 'Repairing geometries...'
    geometry = Geospatial::Geometry.new 'standard_polygons', 'wkb_geometry'
    geometry.repair

    populator = Geospatial::CountryGeometryPopulator
    Country.select(:iso_3).order(:iso_3).each do |country|
      LOGGER.info "Populating geometries for #{country.iso_3}..."
      populator.populate_dissolved_geometries country
      populator.populate_marine_geometries country
    end

    LOGGER.info 'Calculating stats...'
    Geospatial::Calculator.calculate_statistics

    LOGGER.info 'Done.'
  end
end
