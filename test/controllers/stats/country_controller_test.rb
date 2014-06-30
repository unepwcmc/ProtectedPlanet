require 'test_helper'

class Stats::CountryControllerTest < ActionController::TestCase
  test '.show returns a 200 HTTP code' do
    region = FactoryGirl.create(:region)
    FactoryGirl.create(:country, name: 'Orange Emirate', iso: 'PUM', region: region)
    get :show, iso: 'PUM'
    assert_response :success
  end
end
