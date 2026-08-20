require 'test_helper'

# Ogr::Info no longer binds the `gdal` Ruby gem (pinned ~> 2.0, only compiles against
# GDAL 2.x — the image moved to GDAL 3.8.4 for OpenFileGDB). It shells out to the
# `ogrinfo -json` CLI instead, so these tests stub Open3.capture3 rather than the old
# Gdal::Ogr.open -> get_layer -> get_* chain.
class TestOgrInfo < ActiveSupport::TestCase
  def stub_ogrinfo(json, success: true)
    status = mock('status')
    status.stubs(:success?).returns(success)
    Open3.stubs(:capture3).returns([json.to_json, success ? '' : 'boom', status])
  end

  test '.layers returns an array of layer names' do
    stub_ogrinfo({ 'layers' => [{ 'name' => 'Alan' }, { 'name' => 'Kay' }] })
    assert_equal %w[Alan Kay], Ogr::Info.new('/tmp/whatever.gdb').layers
  end

  test '.layers is empty when the dataset reports no layers' do
    stub_ogrinfo({})
    assert_equal [], Ogr::Info.new('/tmp/whatever.gdb').layers
  end

  test '.layers_matching returns layers that match the given regex' do
    Ogr::Info.any_instance.expects(:layers)
      .returns(%w[wdpapolygons wdpa_points wdpa_source])

    ogr_info = Ogr::Info.new 'filename'
    assert_equal %w[wdpapolygons wdpa_points], ogr_info.layers_matching(/wdpa_?po/)
  end

  test '.layer_count returns the number of layers' do
    stub_ogrinfo({ 'layers' => [{ 'name' => 'a' }, { 'name' => 'b' }, { 'name' => 'c' }] })
    assert_equal 3, Ogr::Info.new('/tmp/whatever.gdb').layer_count
  end

  test '.feature_count returns the feature count for the given layer' do
    stub_ogrinfo({ 'layers' => [{ 'name' => 'layer_name', 'featureCount' => 24 }] })
    assert_equal 24, Ogr::Info.new('/tmp/whatever.gdb').feature_count('layer_name')
  end

  test '.feature_count raises when the layer is not in the dataset' do
    stub_ogrinfo({ 'layers' => [] })
    assert_raises(Ogr::Info::OgrInfoError) do
      Ogr::Info.new('/tmp/whatever.gdb').feature_count('missing')
    end
  end

  test 'raises OgrInfoError when the ogrinfo command fails' do
    stub_ogrinfo({}, success: false)
    assert_raises(Ogr::Info::OgrInfoError) { Ogr::Info.new('/tmp/whatever.gdb').layers }
  end
end
