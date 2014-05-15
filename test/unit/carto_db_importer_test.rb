require 'test_helper'
require 'gdal-ruby/ogr'

class TestCartoDbImporter < ActiveSupport::TestCase
  test '.import posts the given file to cartodb and returns when the import is complete' do
    skip
  end

  test '.import returns false object when cartodb fails to import' do
    skip
  end

  test '.import returns false when the file fails to upload' do
    skip
  end

  test 'import returns true when number of rows in cartodb match number of rows in shapefile' do
    tablename = 'table_0'

    layer_mock.stubs(:get_feature_count).returns(200).once
    datasource_mock = mock()
    datasource_mock.expects(:get_layer).returns(layer_mock)
    Gdal::Ogr::expects(:open).returns(datasource_mock)

    stub_request(:get, "https://chewie.cartodb.com/api/v2/sql/").
      with({query: {api_key: '1234', q: "SELECT COUNT(*) FROM #{tablename}"}}).
      to_return(:rows: [{"count"=>200}])

    assert response, "Expected .check to return true if match"
  end

  test 'import returns false when number of rows in cartodb does not match number of rows in shapefile' do
    tablename = 'table_0'

    layer_mock.stubs(:get_feature_count).returns(200).once
    datasource_mock = mock()
    datasource_mock.expects(:get_layer).returns(layer_mock)
    Gdal::Ogr::expects(:open).returns(datasource_mock)

    stub_request(:get, "https://chewie.cartodb.com/api/v2/sql/").
      with({query: {api_key: '1234', q: "SELECT COUNT(*) FROM #{tablename}"}}).
      to_return(:rows: [{"count"=>199}])

    refute response, "Expected .check to return false if do not match"
  end
end
