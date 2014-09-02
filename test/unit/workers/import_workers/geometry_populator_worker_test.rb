require 'test_helper'

class ImportWorkersGeometryPopulatorWorkerTest < ActiveSupport::TestCase
  test '.perform, given a Country ID, populates the country geometries' do
    country = FactoryGirl.create(:country)

    Geospatial::CountryGeometryPopulator.
      expects(:populate_dissolved_geometries).
      with(country)

    Geospatial::CountryGeometryPopulator.
      expects(:populate_marine_geometries).
      with(country)

    ImportWorkers::GeometryPopulatorWorker.
      any_instance.
      expects(:finalise_job)

    ImportWorkers::GeometryPopulatorWorker.new.perform country.id
  end
end
