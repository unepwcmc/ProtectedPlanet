require 'test_helper'
require 'gdal-ruby/ogr'

class TestOgrShapefile < ActiveSupport::TestCase
  test '.split runs the correct ogr2ogr command to split a geo database in to `n` shapefiles and then zips them individually' do
    filename = 'my_gdb.gdb'

    layer_mock = mock()
    layer_mock.stubs(:get_feature_count).returns(200).once
    datasource_mock = mock()
    datasource_mock.expects(:get_layer).returns(layer_mock)
    Gdal::Ogr::expects(:open).returns(datasource_mock)

    OgrShapefile.any_instance.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" 0.shp -dialect sqlite -sql \"SELECT * FROM poly LIMIT 100 OFFSET 0\" #{filename}")
    OgrShapefile.any_instance.expects(:system).with("ogr2ogr -overwrite -skipfailures -f \"ESRI Shapefile\" 1.shp -dialect sqlite -sql \"SELECT * FROM poly LIMIT 100 OFFSET 100\" #{filename}")

    OgrShapefile.any_instance.expects(:system).with("zip 0.zip 0.shx 0.shp 0.dbf 0.prj")
    OgrShapefile.any_instance.expects(:system).with("zip 1.zip 1.shx 1.shp 1.dbf 1.prj")

    File.expects(:delete).with("0.shx", "0.shp", "0.dbf", "0.prj")
    File.expects(:delete).with("1.shx", "1.shp", "1.dbf", "1.prj")

    ogr = OgrShapefile.new
    ogr.split layer: 'poly', filename: filename, number_of_pieces: 2
  end
end
