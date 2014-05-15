require 'test_helper'
require 'gdal-ruby/ogr'

class TestOgrShapefile < ActiveSupport::TestCase
  test '.split runs the correct ogr2ogr command to split a geo database in to `n` shapefiles and then zips them individually' do
    filename = 'my_gdb.gdb'
    layername = 'poly'

    layer_mock = mock()
    layer_mock.stubs(:get_feature_count).returns(200).once
    datasource_mock = mock()
    datasource_mock.expects(:get_layer).returns(layer_mock)
    Gdal::Ogr::expects(:open).returns(datasource_mock)

    OgrShapefile.any_instance.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 poly_0.shp -dialect sqlite -sql \"SELECT * FROM poly LIMIT 100 OFFSET 0\" #{filename}")
    OgrShapefile.any_instance.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 poly_1.shp -dialect sqlite -sql \"SELECT * FROM poly LIMIT 100 OFFSET 100\" #{filename}")

    ogr = OgrShapefile.new
    ogr.split layer: layername, filename: filename, number_of_pieces: 2
  end
end
