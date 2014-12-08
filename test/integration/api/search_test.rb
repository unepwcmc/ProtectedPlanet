require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  test 'GET /search/points?q=manbone returns an array of lat/lng points
   for the results of the given search' do
    results_object = {
      "hits" => {
        "hits" => [{
          "_type" => "protected_area",
          "_source" => {
            "id" => 123,
            "name" => 'Manbone National Swimming Pool',
            "wdpa_id" => 55512345,
            "coordinates" => ['0', '-1']
          }
        }]
      }
    }

    expected_attributes = {
      "id" => 123,
      "name" => 'Manbone National Swimming Pool',
      "wdpa_id" => 55512345,
      "coordinates" => ['0', '-1']
    }

    search_mock = mock().tap { |m| m.stubs(:search).returns(results_object) }
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    get '/api/v3/search/points', q: 'manbone'

    assert_response :success
    assert_equal([expected_attributes], JSON.parse(response.body))
  end
end
