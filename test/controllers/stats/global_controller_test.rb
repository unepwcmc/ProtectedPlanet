require 'test_helper'

class Stats::GlobalControllerTest < ActionController::TestCase
  test '.index returns a 200 HTTP code' do
    skip
    global_region = FactoryGirl.create(:region, iso: 'GL')
    FactoryGirl.create(:regional_statistic, region: global_region, pa_area: 100)

    get :index
    assert_response :success
  end

  test '.index, when there are no global statistics, returns 200' do
    skip
    FactoryGirl.create(:region, iso: 'GL')

    get :index
    assert_response :success
  end
end
