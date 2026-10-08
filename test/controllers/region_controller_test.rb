require 'test_helper'

class RegionControllerTest < ActionController::TestCase

  test ".show action returns 200" do
    seed_cms
    
    region = FactoryBot.create(:region, iso: 'EU')

    country = FactoryBot.create(:country, name: 'Belgium', iso_3: 'BEL', region: region)

    FactoryBot.create(:country_statistic,
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

  # Mirrors the country case: a region holding OECMs opens on the combined tab.
  test '.show defaults to the combined tab only where the region has OECMs' do
    seed_cms

    plain = FactoryBot.create(:region, iso: 'EU')
    with_oecms = FactoryBot.create(:region, iso: 'AF')
    plain_country = FactoryBot.create(:country, name: 'Belgium', iso_3: 'BEL', region: plain)
    oecm_country = FactoryBot.create(:country, name: 'Kenya', iso_3: 'KEN', region: with_oecms)
    {plain_country => {}, oecm_country => { oecms_pa_land_area: 10, oecms_pa_marine_area: 5 }}.each do |country, oecm_areas|
      FactoryBot.create(:country_statistic,
        **oecm_areas,
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
    end
    FactoryBot.create(:protected_area, is_oecm: true, countries: [oecm_country])

    get :show, params: { iso: 'EU' }
    assert_equal ['wdpa'], assigns(:tabs).map { |tab| tab[:id] }
    assert_equal 'wdpa', assigns(:default_tab_id)

    get :show, params: { iso: 'AF' }
    assert_equal %w[wdpa wdpa_oecm], assigns(:tabs).map { |tab| tab[:id] }
    assert_equal 'wdpa_oecm', assigns(:default_tab_id)
  end
end
