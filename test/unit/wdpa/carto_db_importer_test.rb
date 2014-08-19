require 'test_helper'

class TestCartoDbImporter < ActiveSupport::TestCase
  test '#import imports the geometry tables in the WDPA Release File
   Geodatabase' do
    wdpa_release = Wdpa::Release.new

    geometry_tables = {
      "points" => "std_points"
    }
    wdpa_release.expects(:geometry_tables).returns(geometry_tables)

    gdb_path = "/tmp/gdb_path.gdb"
    wdpa_release.expects(:gdb_path).returns(gdb_path)

    Shapefile.any_instance.stubs(:system).returns(true)

    shapefiles = [
      Shapefile.new('points-1.shp'),
      Shapefile.new('points-2.shp'),
      Shapefile.new('points-3.shp'),
      Shapefile.new('points-4.shp'),
      Shapefile.new('points-5.shp'),
    ]

    Ogr::Split.
      expects(:split).
      with(gdb_path, "points", 5, ["wdpaid", "SHAPE"]).
      returns(shapefiles)

    CartoDb::Uploader.any_instance.expects(:upload).with("./points-1.zip").returns(true)
    CartoDb::Uploader.any_instance.expects(:upload).with("./points-2.zip").returns(true)
    CartoDb::Uploader.any_instance.expects(:upload).with("./points-3.zip").returns(true)
    CartoDb::Uploader.any_instance.expects(:upload).with("./points-4.zip").returns(true)
    CartoDb::Uploader.any_instance.expects(:upload).with("./points-5.zip").returns(true)

    expected_table_names = [
      'points-1', 'points-2', 'points-3', 'points-4', 'points-5'
    ]

    default_cartodb_table = 'wdpa_polygons'

    CartoDb::Merger.any_instance.
      expects(:merge).
      with(expected_table_names, ["wdpaid", "the_geom"])

    CartoDb::NameChanger.any_instance.
      expects(:rename).
      with(default_cartodb_table, 'points-1')

    Wdpa::CartoDbImporter.import wdpa_release
  end
end
