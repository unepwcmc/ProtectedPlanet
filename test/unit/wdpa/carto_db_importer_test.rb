require 'test_helper'

class TestCartoDbImporter < ActiveSupport::TestCase
  test '#import imports the geometry tables in the WDPA Release File
   Geodatabase' do
    wdpa_release = Wdpa::Release.new

    geometry_tables = {
      "points" => "std_points",
      "polygons" => "std_polygons"
    }
    wdpa_release.expects(:geometry_tables).returns(geometry_tables)

    gdb_path = "/tmp/gdb_path.gdb"
    wdpa_release.expects(:gdb_path).returns(gdb_path).twice

    Shapefile.any_instance.stubs(:system).returns(true)

    point_shapefiles = [
      Shapefile.new('points-1.shp'),
      Shapefile.new('points-2.shp'),
      Shapefile.new('points-3.shp')
    ]

    Ogr::Split.
      expects(:split).
      with(gdb_path, "points", 5, ["wdpaid", "SHAPE", 'iucn_cat', 'marine']).
      returns(point_shapefiles)

    polygon_shapefiles = [
      Shapefile.new('polygons-1.shp'),
      Shapefile.new('polygons-2.shp')
    ]

    Ogr::Split.
      expects(:split).
      with(gdb_path, "polygons", 5, ["wdpaid", "SHAPE", 'iucn_cat', 'marine']).
      returns(polygon_shapefiles)

    CartoDb::Uploader.any_instance.expects(:upload).with("./points-1.zip").returns(true)
    CartoDb::Uploader.any_instance.expects(:upload).with("./points-2.zip").returns(true)
    CartoDb::Uploader.any_instance.expects(:upload).with("./points-3.zip").returns(true)
    CartoDb::Uploader.any_instance.expects(:upload).with("./polygons-1.zip").returns(true)
    CartoDb::Uploader.any_instance.expects(:upload).with("./polygons-2.zip").returns(true)

    expected_points_table_names = [ 'points-1', 'points-2', 'points-3' ]
    expected_polygons_table_names = [  'polygons-1', 'polygons-2' ]

    CartoDb::Merger.any_instance.expects(:merge).with(expected_points_table_names, ["wdpaid", "the_geom", 'iucn_cat', 'marine'])
    CartoDb::Merger.any_instance.expects(:merge).with(expected_polygons_table_names, ["wdpaid", "the_geom", 'iucn_cat', 'marine'])

    Wdpa::CartoDbImporter.import wdpa_release
  end
end
