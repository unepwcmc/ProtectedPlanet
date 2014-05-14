require 'test_helper'

class TestCartoDbMerger < ActiveSupport::TestCase
  test '.new assigns an options object with the api key and the base uri' do
    cartodb_merger = CartoDb::Merger.new "chewie", "1234"

    query = cartodb_merger.instance_variable_get(:@options)[:query]
    api_key = query[:api_key]

    assert_equal "1234", api_key
    assert_equal "https://chewie.cartodb.com/api/v2/sql", CartoDb::Merger.base_uri
  end

  test 'given an array of table names, .merge concatenates the tables together in CartoDB' do
    table_names = ['poly_1', 'poly_2', 'poly_3']

    stub_request(:get, "https://chewie.cartodb.com/api/v2/sql/").
      with({query: {api_key: '1234', q: ''}}).
      to_return(:status => 200, :body => "", :headers => {})

    cartodb_merger = CartoDb::Merger.new "chewie", "1234"
    response = cartodb_merger.merge table_names

    assert response, "Expected .merge to return true if successful"
  end

  test '.merge returns false if the query fails' do
    stub_request(:get, /chewie.cartodb.com/).
      to_return(:status => 400)

    cartodb_merger = CartoDb::Merger.new "chewie", "1234"
    response = cartodb_merger.merge []

    refute response, "Expected .merge to return false if unsuccessful"
  end
end
