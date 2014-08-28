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
    table_names = ['wdpa_poly_1', 'wdpa_poly_2', 'wdpa_poly_3']

    first_expected_query = '''
      INSERT INTO wdpa_poly_1 (wdpaid, the_geom) SELECT wdpaid, the_geom FROM wdpa_poly_2;
      DROP TABLE wdpa_poly_2;
    '''.squish

    stub_request(:get, "https://chewie.cartodb.com/api/v2/sql/").
      with({query: {api_key: '1234', q: first_expected_query}}).
      to_return(:status => 200, :body => "", :headers => {})

    second_expected_query = '''
      INSERT INTO wdpa_poly_1 (wdpaid, the_geom) SELECT wdpaid, the_geom FROM wdpa_poly_3;
      DROP TABLE wdpa_poly_3;
    '''.squish

    stub_request(:get, "https://chewie.cartodb.com/api/v2/sql/").
      with({query: {api_key: '1234', q: second_expected_query}}).
      to_return(:status => 200, :body => "", :headers => {})


    env = Rails.env
    rename_query = """
      BEGIN;
      DELETE FROM wdpa_poly_#{env};
      INSERT INTO wdpa_poly_#{env} SELECT * FROM wdpa_poly_1;
      DROP TABLE wdpa_poly_1;
      COMMIT;
      """.squish

    stub_request(:get, "https://chewie.cartodb.com/api/v2/sql/").
      with({query: {api_key: '1234', q: rename_query}}).
      to_return(:status => 200, :body => "", :headers => {})

    cartodb_merger = CartoDb::Merger.new "chewie", "1234"
    response = cartodb_merger.merge table_names, ['wdpaid', 'the_geom']

    assert_equal true, response, "Expected .merge to return true if successful"
  end

  test '.merge returns false if the query fails' do
    stub_request(:get, /chewie.cartodb.com/).
      to_return(:status => 400)

    cartodb_merger = CartoDb::Merger.new "chewie", "1234"
    response = cartodb_merger.merge ['an', 'table'], []
    assert_equal false, response, "Expected .merge to return false if unsuccessful"
  end
end
