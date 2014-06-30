require 'test_helper'

class Stats::RegionalControllerTest < ActionController::TestCase
  test '.show returns a 200 HTTP code' do
    FactoryGirl.create(:region, name: 'Americasia', iso: 'AMA')
    get :show, iso: 'AMA'
    assert_response :success
  end
end