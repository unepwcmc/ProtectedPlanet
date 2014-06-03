require 'test_helper'

class TestWdpaGeometryImporterService < ActiveSupport::TestCase
  test '.import imports the given geometries directly in to postgis if
   the PA exists' do
    protected_area = FactoryGirl.create(:protected_area, wdpa_id: 987)
    protected_area_attributes = [{
      wdpaid: 987,
      wkb_geometry: "\x00\x00\x00\x00\x01?\xF0\x00\x00\x00\x00\x00\x00?\xF0\x00\x00\x00\x00\x00\x00" # POINT(1, 1)
    }]

    import_successul = Wdpa::Service::GeometryImporter.import(protected_area_attributes)

    assert import_successul, "Expected the Protected Area to be imported successfully"

    pa_has_valid_geometry = ProtectedArea.
      select('ST_IsValid(the_geom) as geom_valid').
      where(wdpa_id: protected_area.wdpa_id).
      first.geom_valid

    assert pa_has_valid_geometry, "Expected the Protected Area to have a valid geometry"
  end

  test '.import ignores all attributes except the_geom' do
    skip
  end
end
