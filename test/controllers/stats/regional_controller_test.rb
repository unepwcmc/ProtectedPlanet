require 'test_helper'

class Stats::RegionalControllerTest < ActionController::TestCase
  test '.show returns a 200 HTTP code' do
    FactoryGirl.create(:protected_area)
    region = FactoryGirl.create(:region, name: 'Americasia', iso: 'AMA')
    FactoryGirl.create(:regional_statistic, region: region, 
      percentage_pa_cover: 50,
      percentage_pa_land_cover: 50, 
      percentage_pa_eez_cover: 50, 
      percentage_pa_ts_cover: 50)
    get :show, iso: 'AMA'
    assert_response :success
  end
end