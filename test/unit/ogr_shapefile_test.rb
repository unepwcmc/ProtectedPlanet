require 'test_helper'
require 'gdal-ruby/ogr'

class TestOgrShapefile < ActiveSupport::TestCase
  test '.convert_with_query runs the correct ogr2ogr command with the
   given query and returns the shapefile components' do
    filename = '/tmp/my_gdb.gdb'

    Ogr::Shapefile.
      expects(:system).
      with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 /tmp/my_gdb.shp -dialect sqlite -sql \"SELECT * FROM somewhere\" #{filename}").
      returns(true)

    response = Ogr::Shapefile.convert_with_query filename, '/tmp/my_gdb.shp', 'SELECT * FROM somewhere'
    assert response, "Expected convert_with_query to return true on success"
  end
end
