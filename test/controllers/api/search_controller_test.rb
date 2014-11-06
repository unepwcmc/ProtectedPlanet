require 'test_helper'

class Api::SearchControllerTest < ActionController::TestCase
  test 'GET :by_point, given coordinates, returns an array of
    PAs closest to that point' do
    Search.
      expects(:search).
      with('', {filters: {location: {coords: ['2','1'], distance: '1'}}})

    get :by_point, lat: 1, lon: 2, distance: 1

    assert_response :success
  end
end
