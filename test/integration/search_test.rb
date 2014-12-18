require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  test '/search/map/q=manbone renders the search results on a map' do
    search_term = 'manbone'

    get "/search/map/?q=#{search_term}"

    assert_response :success
  end
end
