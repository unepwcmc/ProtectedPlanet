require 'test_helper'

class WdpaCountryGeometryPopulatorTest < ActiveSupport::TestCase
  test '#populate creates a worker to populate the geometries of each
   Country' do
    st_lucia = FactoryGirl.create(:country, iso_3: 'STL')

    repair_mock = mock()
    repair_mock.expects(:repair)
    Geospatial::Geometry.
      expects(:new).
      with('standard_polygons', 'wkb_geometry').
      returns(repair_mock)

    ImportWorkers::GeometryPopulatorWorker.
      expects(:perform_async).
      with(st_lucia.id)

    Wdpa::CountryGeometryPopulator.populate
  end
end
