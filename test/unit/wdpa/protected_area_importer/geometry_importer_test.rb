require 'test_helper'

class TestWdpaGeometryImporterService < ActiveSupport::TestCase
  test '.import updates all the PA geometries with the geometries in the
   given WDPA Release' do
    table_names = {
      "geom1" => "standard_points",
      "geom2" => "standard_polygons"
    }


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
        WHERE pa.site_id = import.wdpaid;
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET second_geom = import.second_geometry
        FROM #{table_names["geom1"]} import
        WHERE pa.site_id = import.wdpaid;
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET the_geom_longitude = (
          CASE ST_IsValid(the_geom)
            WHEN TRUE THEN ST_X(ST_Centroid(the_geom))
            WHEN FALSE THEN ST_X(ST_Centroid(ST_MakeValid(the_geom)))
          END
        ),
        the_geom_latitude = (
          CASE ST_IsValid(the_geom)
            WHEN TRUE THEN ST_Y(ST_Centroid(the_geom))
            WHEN FALSE THEN ST_Y(ST_Centroid(ST_MakeValid(the_geom)))
          END
        );
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET second_geom_longitude = (
          CASE ST_IsValid(second_geom)
            WHEN TRUE THEN ST_X(ST_Centroid(second_geom))
            WHEN FALSE THEN ST_X(ST_Centroid(ST_MakeValid(second_geom)))
          END
        ),
        second_geom_latitude = (
          CASE ST_IsValid(second_geom)
            WHEN TRUE THEN ST_Y(ST_Centroid(second_geom))
            WHEN FALSE THEN ST_Y(ST_Centroid(ST_MakeValid(second_geom)))
          END
        );
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET the_geom = import.wkb_geometry
        FROM #{table_names["geom2"]} import
        WHERE pa.site_id = import.wdpaid;
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET second_geom = import.second_geometry
        FROM #{table_names["geom2"]} import
        WHERE pa.site_id = import.wdpaid;
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET the_geom_longitude = (
          CASE ST_IsValid(the_geom)
            WHEN TRUE THEN ST_X(ST_Centroid(the_geom))
            WHEN FALSE THEN ST_X(ST_Centroid(ST_MakeValid(the_geom)))
          END
        ),
        the_geom_latitude = (
          CASE ST_IsValid(the_geom)
            WHEN TRUE THEN ST_Y(ST_Centroid(the_geom))
            WHEN FALSE THEN ST_Y(ST_Centroid(ST_MakeValid(the_geom)))
          END
        );
      """.squish)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE protected_areas pa
        SET second_geom_longitude = (
          CASE ST_IsValid(second_geom)
            WHEN TRUE THEN ST_X(ST_Centroid(second_geom))
            WHEN FALSE THEN ST_X(ST_Centroid(ST_MakeValid(second_geom)))
          END
        ),
        second_geom_latitude = (
          CASE ST_IsValid(second_geom)
            WHEN TRUE THEN ST_Y(ST_Centroid(second_geom))
            WHEN FALSE THEN ST_Y(ST_Centroid(ST_MakeValid(second_geom)))
          END
        );
      """.squish)

    import_successful = Wdpa::ProtectedAreaImporter::GeometryImporter.import
    assert import_successful, "Expected the geometry import to be successful"
  end

  test '.import returns false if any update query fails' do
    ActiveRecord::Base.connection.
      expects(:execute).
      raises(ActiveRecord::StatementInvalid).
      once

    import_successful = Wdpa::ProtectedAreaImporter::GeometryImporter.import
    refute import_successful, "Expected import to fail"
  end
end
