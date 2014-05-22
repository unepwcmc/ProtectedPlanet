require 'test_helper'
require 'gdal-ruby/ogr'

class TestOgrSplit < ActiveSupport::TestCase
  test '.split runs the correct ogr2ogr command to split a geo database
   in to `n` shapefiles and then zips them individually' do
    filename = 'my_gdb.gdb'
    layer_name = 'poly'
    column_name = ['wdpaid']

    layer_mock = mock()
    layer_mock.stubs(:get_feature_count).returns(200).once
    datasource_mock = mock()
    datasource_mock.expects(:get_layer).returns(layer_mock)
    Gdal::Ogr::expects(:open).returns(datasource_mock)

    Ogr::Shapefile.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 ./poly_0.shp -dialect sqlite -sql \"SELECT wdpaid FROM poly LIMIT 100 OFFSET 0\" #{filename}")
    Ogr::Shapefile.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 ./poly_1.shp -dialect sqlite -sql \"SELECT wdpaid FROM poly LIMIT 100 OFFSET 100\" #{filename}")

    expected_shapefile_paths = ['./poly_0.shp', './poly_1.shp']

    ogr = Ogr::Split.new
    shapefile_paths = ogr.split filename, layer_name, 2, column_name

    assert_equal expected_shapefile_paths, shapefile_paths
  end

  test 'if column_names are not passed .split uses a *' do
    filename = 'my_gdb.gdb'
    layer_name = 'poly'


    layer_mock = mock()
    layer_mock.stubs(:get_feature_count).returns(200).once
    datasource_mock = mock()
    datasource_mock.expects(:get_layer).returns(layer_mock)
    Gdal::Ogr::expects(:open).returns(datasource_mock)

    Ogr::Shapefile.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 ./poly_0.shp -dialect sqlite -sql \"SELECT * FROM poly LIMIT 200 OFFSET 0\" #{filename}")
  
    expected_shapefile_paths = ['./poly_0.shp']

    ogr = Ogr::Split.new
    shapefile_paths = ogr.split filename, layer_name, 1

    assert_equal expected_shapefile_paths, shapefile_paths
  end
end
