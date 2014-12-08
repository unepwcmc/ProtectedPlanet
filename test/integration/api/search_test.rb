require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  test 'GET /search/points?q=manbone returns an array of lat/lng points
   for the results of the given search' do
    expected_attributes = {
      "id" => 1234567,
      "name" => 'Manbone National Swimming Pool',
      "wdpa_id" => 55512345,
      "the_geom_latitude" => '0',
      "the_geom_longitude" => '-1'
    }

    pa = FactoryGirl.create(:protected_area, expected_attributes)

    results_object = {
      "hits" => {
        "hits" => [{
          "_type" => "protected_area",
          "_source" => {
            "id" => pa.id
          }
        }]
      }
    }

    search_mock = mock().tap { |m| m.stubs(:search).returns(results_object) }
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    get '/api/v3/search/points', q: 'manbone'

    assert_response :success
    assert_equal([expected_attributes], JSON.parse(response.body))
  end
end
