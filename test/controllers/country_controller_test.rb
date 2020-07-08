require 'test_helper'

class CountryControllerTest < ActionController::TestCase
  test '.show returns a 200 HTTP code' do
    FactoryGirl.create(:region, iso: 'GL')

    region = FactoryGirl.create(:region)

    country = FactoryGirl.create(:country, name: 'Orange Emirate', iso_3: 'PUM', region: region)

    FactoryGirl.create(:country_statistic,
      country: country,
      pa_area: 100,
      percentage_pa_cover: 50,
      percentage_pa_land_cover: 50,
      percentage_pa_eez_cover: 50,
      percentage_pa_ts_cover: 50,
      polygons_count: 100,
      points_count: 100
    )

    FactoryGirl.create(:pame_statistic, country: country)

    seed_cms
    
    get :show, params: {iso: 'PUM'}
    assert_response :success
  end
end
