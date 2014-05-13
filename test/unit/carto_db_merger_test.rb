require 'test_helper'

class TestCartoDbMerger < ActiveSupport::TestCase
  test 'given an array of table names, .merge concatenates the tables together in CartoDB' do
    table_names = ['poly_1', 'poly_2', 'poly_3']

    cartodb_username = Rails.application.secrets.cartodb_username
    cartodb_api_key  = Rails.application.secrets.cartodb_api_key

    response = Typhoeus::Response.new(code: 200)
    Typhoeus
      .expects(:get)
      .with("http://#{cartodb_username}.cartodb.com/api/v2/sql", 
        params: {
          q: 'INSERT INTO poly_1 (SELECT * FROM poly_2 UNION ALL SELECT * FROM poly_3)',
          api_key: cartodb_api_key
        }
      )
      .returns(response)

    cartodb_merger = CartoDbMerger.new
    response = cartodb_merger.merge table_names

    assert response, "Expected .merge to return true if successful"
  end
end