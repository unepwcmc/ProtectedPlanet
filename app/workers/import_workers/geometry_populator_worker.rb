class ImportWorkers::GeometryPopulatorWorker < ImportWorker
  def perform country_id
    country = Country.find(country_id)
    if country
      populator = Geospatial::CountryGeometryPopulator
      populator.populate_dissolved_geometries country
      populator.populate_marine_geometries country
    end
  ensure
    finalise_job
  end
end
