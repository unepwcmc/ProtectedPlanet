require 'test_helper'
require 'gdal-ruby/ogr'

class TestOgrShapefile < ActiveSupport::TestCase
  test '.convert_with_query runs the correct ogr2ogr command with the
   given query and returns the shapefile components' do
    filename = '/tmp/my_gdb.gdb'

    OgrShapefile.any_instance.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 /tmp/my_gdb.shp -dialect sqlite -sql \"SELECT * FROM somewhere\" #{filename}")
    Shapefile.any_instance.expects(:system).with("zip /tmp/my_gdb.zip /tmp/my_gdb.shx /tmp/my_gdb.shp /tmp/my_gdb.dbf /tmp/my_gdb.prj")

    ogr = OgrShapefile.new filename
    shapefile_components = ogr.convert_with_query "SELECT * FROM somewhere", '/tmp/my_gdb.shp'

    assert_equal '/tmp/my_gdb.zip', shapefile_components
  end
end
