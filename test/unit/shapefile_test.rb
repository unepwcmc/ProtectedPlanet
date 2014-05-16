require 'test_helper'

class TestShapefile < ActiveSupport::TestCase
  test '.filename returns the filename for the given path with no extension' do
    shapefile = Shapefile.new "/tmp/hey/file.shp"
    assert_equal "file", shapefile.filename
  end

  test '.path returns the full path shapefile' do
    shapefile = Shapefile.new "/tmp/hey/file.shp"
    assert_equal "/tmp/hey/file.shp", shapefile.path
  end

  test '.components returns the complementary files for the given shapefile' do
    shapefile = Shapefile.new "/tmp/hey/file.shp"
    assert_equal ['/tmp/hey/file.shx', '/tmp/hey/file.shp', '/tmp/hey/file.dbf', '/tmp/hey/file.prj'], shapefile.components
  end

  test '.compress zips the shapefile and its components, and returns the zip path' do
    Shapefile.any_instance.expects(:system).with("zip /tmp/file.zip /tmp/file.shx /tmp/file.shp /tmp/file.dbf /tmp/file.prj")

    shapefile = Shapefile.new "/tmp/file.shp"
    zip_file = shapefile.compress

    assert_equal "/tmp/file.zip", zip_file
  end
end
