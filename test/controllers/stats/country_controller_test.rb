require 'test_helper'

class Stats::CountryControllerTest < ActionController::TestCase
  test '.show returns a 200 HTTP code' do
    FactoryGirl.create(:country, name: 'Orange Emirate', iso: 'PUM')
    get :show, iso: 'PUM'
    assert_response :success
  end
end