require 'test_helper'

class TestWdpaGeometryImporterService < ActiveSupport::TestCase
  test '.import updates all the PA geometries with the geometries in the import table' do
    table_name = 'wdpa_poly_apr2014'

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET the_geom = import.wkb_geometry
        FROM #{table_name} import
        WHERE pa.wdpa_id = import.wdpaid;
      """).once

    import_successful = Wdpa::Service::GeometryImporter.import table_name
    assert import_successful, "Expected the geometry import to be successful"
  end

  test '.import returns false if any update query fails' do
    ActiveRecord::Base.connection.
      expects(:execute).
      raises(ActiveRecord::StatementInvalid).
      once

    import_successful = Wdpa::Service::GeometryImporter.import 'table_name'

    refute import_successful, "Expected import to fail"
  end
end
