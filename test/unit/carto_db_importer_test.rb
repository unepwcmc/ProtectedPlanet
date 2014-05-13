require 'test_helper'

class TestCartoDbImporter < ActiveSupport::TestCase
  test '.import posts the given file to cartodb and returns when the import is complete' do
    file_mock = mock()
    File.expects(:open).with('an_file.zip', 'r').returns(file_mock)

    response = Typhoeus::Response.new(code: 200, body: "{\"item_queue_id\":\"12345\"}")
    Typhoeus
      .expects(:post)
      .with("https://carbon-tool.cartodb.com/api/v1/imports/", params: {api_key: '1234'}, body: {file: file_mock})
      .returns(response)

    response = Typhoeus::Response.new(code: 200, body: "{\"state\":\"complete\"}")
    Typhoeus
      .expects(:get)
      .with("https://carbon-tool.cartodb.com/api/v1/imports/12345", params: {api_key: '1234'})
      .returns(response)

    cartodb_importer = CartoDbImporter.new username: 'carbon-tool', api_key: '1234'
    response = cartodb_importer.import 'an_file.zip'

    assert response, "Expected importer to return true on success"
  end

  test '.import returns an error object when cartodb fails to import' do
    file_mock = mock()
    File.expects(:open).with('an_file.zip', 'r').returns(file_mock)

    response = Typhoeus::Response.new(code: 200, body: "{\"item_queue_id\":\"12345\"}")
    Typhoeus
      .expects(:post)
      .with("https://carbon-tool.cartodb.com/api/v1/imports/", params: {api_key: '1234'}, body: {file: file_mock})
      .returns(response)

    response = Typhoeus::Response.new(code: 200, body: "{\"state\":\"failure\"}")
    Typhoeus
      .expects(:get)
      .with("https://carbon-tool.cartodb.com/api/v1/imports/12345", params: {api_key: '1234'})
      .returns(response)

    cartodb_importer = CartoDbImporter.new username: 'carbon-tool', api_key: '1234'
    response = cartodb_importer.import 'an_file.zip'

    assert !response, "Expected importer to return false on error"
  end

  test '.import returns false when the file fails to upload' do
    file_mock = mock()
    File.expects(:open).with('an_file.zip', 'r').returns(file_mock)

    response = Typhoeus::Response.new(code: 500)
    Typhoeus
      .expects(:post)
      .with("https://carbon-tool.cartodb.com/api/v1/imports/", params: {api_key: '1234'}, body: {file: file_mock})
      .returns(response)

    cartodb_importer = CartoDbImporter.new username: 'carbon-tool', api_key: '1234'
    response = cartodb_importer.import 'an_file.zip'

    assert !response, "Expected importer to return false on error"
  end
end