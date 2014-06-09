require 'test_helper'

class TestOgrInfo < ActiveSupport::TestCase
  test '.layers returns an array of layer names' do
    filename = '/tmp/whatever.gdb'

    ogr_mock = mock()
    ogr_mock.stubs(:get_layer_count).returns(2)

    first_layer_mock = mock()
    first_layer_mock.stubs(:get_name).returns("Alan")
    second_layer_mock = mock()
    second_layer_mock.stubs(:get_name).returns("Kay")
    ogr_mock.stubs(:get_layer).
      returns(first_layer_mock).returns(second_layer_mock)

    Gdal::Ogr.
      expects(:open).
      with(filename).
      returns(ogr_mock)

    ogr_info = Ogr::Info.new filename
    assert_equal ["Alan", "Kay"], ogr_info.layers
  end

  test '.layers_matching returns layers that match the given regex' do
    Ogr::Info.
      any_instance.
      expects(:layers).
      returns(["wdpapolygons", "wdpa_points", "wdpa_source"])

    ogr_info = Ogr::Info.new 'filename'
    assert_equal ["wdpapolygons", "wdpa_points"], ogr_info.layers_matching(/wdpa_?po/)
  end

  test '.layer_count returns the number of layers' do
    filename = '/tmp/whatever.gdb'

    ogr_mock = mock()
    ogr_mock.stubs(:get_layer_count).returns(3)

    Gdal::Ogr.
      expects(:open).
      with(filename).
      returns(ogr_mock)

    ogr_info = Ogr::Info.new filename
    assert_equal 3, ogr_info.layer_count
  end

  test '.feature_count returns the feature count for the given layer' do
    filename = '/tmp/whatever.gdb'

    layer_mock = mock()
    layer_mock.stubs(:get_feature_count).returns(24)
    ogr_mock = mock()
    ogr_mock.stubs(:get_layer).returns(layer_mock)

    Gdal::Ogr.
      expects(:open).
      with(filename).
      returns(ogr_mock)

    ogr_info = Ogr::Info.new filename
    assert_equal 24, ogr_info.feature_count('layer_name')
  end
end
