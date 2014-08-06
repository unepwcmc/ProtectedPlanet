require 'test_helper'
require 'gdal-ruby/ogr'

class TestCartoDbNameChanger < ActiveSupport::TestCase

  test 'given the temp and default table names .rename inserts new data on default table and removes temporary in CartoDB' do
    default_table = 'default'
    temp_table = 'temp'

    query = """
            BEGIN;
            DELETE FROM default;
            INSERT INTO default SELECT * FROM temp;
            DROP TABLE temp;
            COMMIT;
            """.squish

    stub_request(:get, "https://chewie.cartodb.com/api/v2/sql/").
      with({query: {api_key: '1234', q: query}}).
      to_return(:status => 200, :body => "", :headers => {})


    cartodb_name_changer = CartoDb::NameChanger.new "chewie", "1234"
    response = cartodb_name_changer.rename default_table,temp_table

    assert_equal true, response, "Expected .delete_current to return true if successful"
  end
end
