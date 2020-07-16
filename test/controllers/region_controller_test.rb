require 'test_helper'

class RegionControllerTest < ActionController::TestCase

  test ".show action returns 200" do
    seed_cms
    
    region = FactoryGirl.create(:region, iso: 'EU')

    country = FactoryGirl.create(:country, name: 'Belgium', iso_3: 'BEL', region: region)

    FactoryGirl.create(:country_statistic,
      country: country,
      pa_area: 100,
      land_area: 50,
      pa_land_area: 50,
      percentage_pa_marine_cover: 50,
      pa_marine_area: 50,
      marine_area: 50,
      percentage_pa_land_cover: 50,
      polygons_count: 100,
      points_count: 100
    )

    get :show, params: {iso: 'EU'}
    assert_response :success
  end

end
