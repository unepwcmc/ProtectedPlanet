require 'test_helper'

class Stats::RegionalControllerTest < ActionController::TestCase
  test '.show returns a 200 HTTP code' do
    global_region = FactoryGirl.create(:region, iso: 'GL')
    FactoryGirl.create(:regional_statistic, region: global_region, pa_area: 100)

    region = FactoryGirl.create(:region, name: 'Americasia', iso: 'AMA')
    FactoryGirl.create(:regional_statistic, region: region,
      pa_area: 100,
      percentage_pa_cover: 50,
      percentage_pa_land_cover: 50,
      percentage_pa_eez_cover: 50,
      percentage_pa_ts_cover: 50)

    get :show, iso: 'AMA'
    assert_response :success
  end

  test '.show, given a Region with no stats, returns 200' do
    global_region = FactoryGirl.create(:region, iso: 'GL')
    FactoryGirl.create(:regional_statistic, region: global_region, pa_area: 100)

    FactoryGirl.create(:region, name: 'Americasia', iso: 'AMA')

    get :show, iso: 'AMA'
    assert_response :success
  end
end
