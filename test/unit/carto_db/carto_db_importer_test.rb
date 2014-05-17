require 'test_helper'
require 'gdal-ruby/ogr'

class TestCartoDbImporter < ActiveSupport::TestCase
  test '.import posts the given file to cartodb and returns when the import is complete' do
    import_id = 'really-long-uuid'

    stub_request(:post, "https://chewie.cartodb.com/api/v1/imports/").
      with({body: {api_key: '1234'}}).
      to_return(:status => 200, :body => "{\"item_queue_id\": \"#{import_id}\"}")

    stub_request(:get, "https://chewie.cartodb.com/api/v1/imports/#{import_id}").
      with({query: {api_key: '1234'}}).
      to_return(:status => 200, :body => "{\"state\": \"complete\"}")

    importer = CartoDb::Importer.new "chewie", "1234"
    imported = importer.import __FILE__

    assert imported, "Expected importer to return true on success"
  end

  test '.import returns false object when cartodb fails to import' do
    import_id = 'really-long-uuid'

    stub_request(:post, "https://chewie.cartodb.com/api/v1/imports/").
      with({body: {api_key: '1234'}}).
      to_return(:status => 200, :body => "{\"item_queue_id\": \"#{import_id}\"}")

    stub_request(:get, "https://chewie.cartodb.com/api/v1/imports/#{import_id}").
      with({query: {api_key: '1234'}}).
      to_return(:status => 200, :body => "{\"state\": \"failure\"}")

    importer = CartoDb::Importer.new "chewie", "1234"
    imported = importer.import __FILE__

    refute imported, "Expected importer to return false on failure"
  end

  test '.import returns false when the file fails to upload' do
    stub_request(:post, "https://chewie.cartodb.com/api/v1/imports/").
      with({body: {api_key: '1234'}}).
      to_return(:status => 500, :body => "")

    importer = CartoDb::Importer.new "chewie", "1234"
    imported = importer.import __FILE__

    refute imported, "Expected importer to return false on failure"
  end
end
