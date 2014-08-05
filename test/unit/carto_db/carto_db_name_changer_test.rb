require 'test_helper'
require 'gdal-ruby/ogr'

class TestCartoDbNameChanger < ActiveSupport::TestCase

  test 'given the default table name .delete_current removes all rows from default table in CartoDB' do
    default_table = 'default'

    query = """
            BEGIN;
            DELETE FROM default;
            COMMIT;
            """.squish

    stub_request(:get, "https://chewie.cartodb.com/api/v2/sql/").
      with({query: {api_key: '1234', q: query}}).
      to_return(:status => 200, :body => "", :headers => {})


    cartodb_name_changer = CartoDb::NameChanger.new "chewie", "1234"
    response = cartodb_name_changer.delete_current default_table

    assert_equal true, response, "Expected .delete_current to return true if successful"
  end

  test 'given the temp and default table names .insert_new inserts new rows on default table in CartoDB' do
    default_table = 'default'
    temp_table = 'temp'

    query = """
            BEGIN;
            INSERT INTO default SELECT * FROM temp;
            COMMIT;
            """.squish

    stub_request(:get, "https://chewie.cartodb.com/api/v2/sql/").
      with({query: {api_key: '1234', q: query}}).
      to_return(:status => 200, :body => "", :headers => {})


    cartodb_name_changer = CartoDb::NameChanger.new "chewie", "1234"
    response = cartodb_name_changer.insert_new default_table,temp_table

    assert_equal true, response, "Expected .delete_current to return true if successful"

  end

  test 'given the temp table name, .drop_temp drops it in CartoDB' do
    temp_table = 'temp'

    query = """
            DROP TABLE temp;
            """.squish

    stub_request(:get, "https://chewie.cartodb.com/api/v2/sql/").
      with({query: {api_key: '1234', q: query}}).
      to_return(:status => 200, :body => "", :headers => {})


    cartodb_name_changer = CartoDb::NameChanger.new "chewie", "1234"
    response = cartodb_name_changer.drop_temp temp_table

    assert_equal true, response, "Expected .delete_current to return true if successful"
  end
end
