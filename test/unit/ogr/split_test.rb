require 'test_helper'

class TestOgrSplit < ActiveSupport::TestCase
  test '#split runs the correct ogr2ogr command to split a geo database
   in to `n` shapefiles and returns each as a Shapefile' do
    filename = 'my_gdb.gdb'
    layer_name = 'poly'
    column_name = ['wdpaid']

    # The gdal gem is gone (it only builds against GDAL 2.x). Ogr::Info now shells
    # out to the ogrinfo CLI, so stub its public API rather than the old
    # Gdal::Ogr.open -> get_layer -> get_feature_count chain.
    Ogr::Info.any_instance.expects(:feature_count).with(layer_name).returns(200)

    Ogr::Shapefile.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 ./poly_0.shp -dialect sqlite -sql \"SELECT wdpaid FROM poly LIMIT 100 OFFSET 0\" #{filename}")
    Ogr::Shapefile.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 ./poly_1.shp -dialect sqlite -sql \"SELECT wdpaid FROM poly LIMIT 100 OFFSET 100\" #{filename}")

    expected_shapefile_paths = ['./poly_0.shp', './poly_1.shp']

    shapefiles = Ogr::Split.split filename, layer_name, 2, column_name

    assert_equal expected_shapefile_paths, shapefiles.map(&:path)
  end

  test 'if column_names are not passed .split uses a *' do
    filename = 'my_gdb.gdb'
    layer_name = 'poly'


    # The gdal gem is gone (it only builds against GDAL 2.x). Ogr::Info now shells
    # out to the ogrinfo CLI, so stub its public API rather than the old
    # Gdal::Ogr.open -> get_layer -> get_feature_count chain.
    Ogr::Info.any_instance.expects(:feature_count).with(layer_name).returns(200)

    Ogr::Shapefile.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" -lco ENCODING=UTF-8 ./poly_0.shp -dialect sqlite -sql \"SELECT * FROM poly LIMIT 200 OFFSET 0\" #{filename}")

    shapefile = Ogr::Split.split(filename, layer_name, 1).first

    expected_shapefile_path = './poly_0.shp'

    assert_kind_of Shapefile, shapefile
    assert_equal expected_shapefile_path, shapefile.path
  end
end
