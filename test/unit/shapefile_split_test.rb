require 'test_helper'
require 'gdal-ruby/ogr'

class TestShapefileSplit < ActiveSupport::TestCase
  test '.split runs the correct ogr2ogr command to split a geo database in to `n` shapefiles and then zips them individually' do
    filename = 'my_gdb.gdb'
    layername = 'poly'

    layer_mock = mock()
    layer_mock.stubs(:get_feature_count).returns(200).once
    datasource_mock = mock()
    datasource_mock.expects(:get_layer).returns(layer_mock)
    Gdal::Ogr::expects(:open).returns(datasource_mock)

    Ogr::Shapefile.any_instance.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 ./poly_0.shp -dialect sqlite -sql \"SELECT * FROM poly LIMIT 100 OFFSET 0\" #{filename}")
    Ogr::Shapefile.any_instance.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 ./poly_1.shp -dialect sqlite -sql \"SELECT * FROM poly LIMIT 100 OFFSET 100\" #{filename}")

    Shapefile.any_instance.expects(:system).with("zip ./poly_0.zip ./poly_0.shx ./poly_0.shp ./poly_0.dbf ./poly_0.prj")
    Shapefile.any_instance.expects(:system).with("zip ./poly_1.zip ./poly_1.shx ./poly_1.shp ./poly_1.dbf ./poly_1.prj")

    ogr = ShapefileSplit.new
    zip_files = ogr.split layer: layername, filename: filename, number_of_pieces: 2

    assert_equal ['./poly_0.zip', './poly_1.zip'], zip_files
  end
end
