require 'test_helper'

class TestWdpaGeometryImporterService < ActiveSupport::TestCase
  test '.import updates all the PA geometries with the geometries in the
   given WDPA Release' do
    table_names = {
      "geom1" => "std_geom1",
      "geom2" => "std_geom2"
    }

    wdpa_release = Wdpa::Release.new
    wdpa_release.expects(:geometry_tables).returns(table_names)

    Wdpa::DataStandard.expects(:standard_attributes).returns({
      :desig_type   => {name: :jurisdiction, type: :string},
      :wkb_geometry => {name: :the_geom, type: :geometry},
      :second_geometry => {name: :second_geom, type: :geometry}
    }).at_least_once

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET the_geom = import.wkb_geometry
        FROM #{table_names["geom1"]} import
        WHERE pa.wdpa_id = import.wdpaid;
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET second_geom = import.second_geometry
        FROM #{table_names["geom1"]} import
        WHERE pa.wdpa_id = import.wdpaid;
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET the_geom_longitude = ST_X(ST_Centroid(the_geom)),
            the_geom_latitude = ST_Y(ST_Centroid(the_geom));
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET second_geom_longitude = ST_X(ST_Centroid(second_geom)),
            second_geom_latitude = ST_Y(ST_Centroid(second_geom));
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET the_geom = import.wkb_geometry
        FROM #{table_names["geom2"]} import
        WHERE pa.wdpa_id = import.wdpaid;
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET second_geom = import.second_geometry
        FROM #{table_names["geom2"]} import
        WHERE pa.wdpa_id = import.wdpaid;
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET the_geom_longitude = ST_X(ST_Centroid(the_geom)),
            the_geom_latitude = ST_Y(ST_Centroid(the_geom));
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET second_geom_longitude = ST_X(ST_Centroid(second_geom)),
            second_geom_latitude = ST_Y(ST_Centroid(second_geom));
      """.squish)

    import_successful = Wdpa::ProtectedAreaImporter::GeometryImporter.import wdpa_release
    assert import_successful, "Expected the geometry import to be successful"
  end

  test '.import returns false if any update query fails' do
    wdpa_release = Wdpa::Release.new
    wdpa_release.expects(:geometry_tables).returns(["geom1"])

    ActiveRecord::Base.connection.
      expects(:execute).
      raises(ActiveRecord::StatementInvalid).
      once

    import_successful = Wdpa::ProtectedAreaImporter::GeometryImporter.import wdpa_release

    refute import_successful, "Expected import to fail"
  end
end
