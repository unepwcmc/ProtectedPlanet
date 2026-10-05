require 'test_helper'

# Characterizes the .gdb export command building (previously untested) and locks the
# driver to OpenFileGDB (was the proprietary Esri "FileGDB" SDK driver). `system` is
# stubbed so no real ogr2ogr runs -- the current dev image's GDAL 2.2.3 has OpenFileGDB
# read-only, so real .gdb writing is validated separately against a GDAL 3.6+ container.
class OgrPostgresGdbExportTest < ActiveSupport::TestCase
  def setup
    Ogr::Postgres.stubs(:db_config).returns({ host: 'h', username: 'u', password: nil, database: 'd' })
  end

  def capture_export_command(file_name, geom_type)
    File.stubs(:exist?).returns(false) # brand-new file -> create mode
    captured = nil
    Ogr::Postgres.stubs(:system).with { |cmd| captured = cmd; true }.returns(true)
    Ogr::Postgres.export(:gdb, file_name, 'SELECT * FROM v', geom_type)
    captured
  end

  test 'DRIVERS maps :gdb to OpenFileGDB, not the Esri SDK driver' do
    assert_equal 'OpenFileGDB', Ogr::Postgres::DRIVERS[:gdb]
  end

  test 'export(:gdb) builds an ogr2ogr command using the OpenFileGDB driver' do
    cmd = capture_export_command('/tmp/WDPA_Jan2024_Public_polygons.gdb', 'multipolygon')
    assert_match(/ogr2ogr/, cmd)
    assert_match(/-f "OpenFileGDB"/, cmd)
    # GEOMETRY_NAME=SHAPE keeps the geometry column named SHAPE (Esri convention) --
    # OpenFileGDB would otherwise name it after the source column (the_geom).
    assert_match(/-lco "GEOMETRY_NAME=SHAPE"/, cmd)
    assert_match(/-nlt "MULTIPOLYGON"/, cmd)
    # the geometry-type layer is named from the download filename convention
    assert_match(/-nln "WDPA_poly_Jan2024"/, cmd)
    refute_match(/-f "FileGDB"/, cmd, 'must not use the proprietary Esri driver')
  end

  test 'export(:gdb) appends with -update when the .gdb already exists (multi-layer)' do
    File.stubs(:exist?).returns(true) # existing .gdb -> update/append mode
    captured = nil
    Ogr::Postgres.stubs(:system).with { |cmd| captured = cmd; true }.returns(true)
    Ogr::Postgres.export(:gdb, '/tmp/WDPA_Jan2024_Public_points.gdb', 'SELECT * FROM v', 'multipoint')
    assert_match(/-update/, captured)
    assert_match(/-f "OpenFileGDB"/, captured)
  end
end
