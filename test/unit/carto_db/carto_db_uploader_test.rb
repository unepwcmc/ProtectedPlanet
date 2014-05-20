require 'test_helper'
require 'gdal-ruby/ogr'

class TestCartoDbUploader < ActiveSupport::TestCase
  test '.upload posts the given file to cartodb and returns when the upload is complete' do
    upload_id = 'really-long-uuid'

    stub_request(:post, "https://chewie.cartodb.com/api/v1/imports/").
      with({ headers: {'Content-Length' => /.*/, 'Content-Type' => /multipart\/form-data;.*/} }).
      to_return(:status => 200, :body => "{\"item_queue_id\": \"#{upload_id}\"}")

    stub_request(:get, "https://chewie.cartodb.com/api/v1/imports/#{upload_id}").
      with({query: {api_key: '1234'}}).
      to_return(:status => 200, :body => "{\"state\": \"complete\"}")

    uploader = CartoDb::Uploader.new "chewie", "1234"
    uploaded = uploader.upload __FILE__

    assert uploaded, "Expected uploader to return true on success"
  end

  test '.upload returns false object when cartodb fails to upload' do
    upload_id = 'really-long-uuid'

    stub_request(:post, "https://chewie.cartodb.com/api/v1/imports/").
      with({ headers: {'Content-Length' => /.*/, 'Content-Type' => /multipart\/form-data;.*/} }).
      to_return(:status => 200, :body => "{\"item_queue_id\": \"#{upload_id}\"}")

    stub_request(:get, "https://chewie.cartodb.com/api/v1/imports/#{upload_id}").
      with({query: {api_key: '1234'}}).
      to_return(:status => 200, :body => "{\"state\": \"failure\"}")

    uploader = CartoDb::Uploader.new "chewie", "1234"
    uploaded = uploader.upload __FILE__

    refute uploaded, "Expected uploader to return false on failure"
  end

  test '.upload sleeps if the import does not complete or fail immediately' do
    upload_id = 'really-long-uuid'

    stub_request(:post, "https://chewie.cartodb.com/api/v1/imports/").
      with({ headers: {'Content-Length' => /.*/, 'Content-Type' => /multipart\/form-data;.*/} }).
      to_return(:status => 200, :body => "{\"item_queue_id\": \"#{upload_id}\"}")

    stub_request(:get, "https://chewie.cartodb.com/api/v1/imports/#{upload_id}").
      with({query: {api_key: '1234'}}).
      to_return([{
        :status => 200, :body => "{\"state\": \"uploading\"}"
      },{
        :status => 200, :body => "{\"state\": \"failure\"}"
      }])

    CartoDb::Uploader.any_instance.expects(:sleep).with(5)

    uploader = CartoDb::Uploader.new "chewie", "1234"
    uploaded = uploader.upload __FILE__
  end

  test '.upload returns false when the file fails to upload' do
    stub_request(:post, "https://chewie.cartodb.com/api/v1/imports/").
      with({ headers: {'Content-Length' => /.*/, 'Content-Type' => /multipart\/form-data;.*/} }).
      to_return(:status => 500, :body => "")

    uploader = CartoDb::Uploader.new "chewie", "1234"
    uploaded = uploader.upload __FILE__

    refute uploaded, "Expected uploader to return false on failure"
  end
end
