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
  # The overview figures sit in the same cache entry as the tab stats so that a
  # warm region page never has to load the region's countries or their statistics.
  test '.show serves the overview figures from cache without re-reading countries' do
    seed_cms
    Rails.cache.clear

    region = FactoryBot.create(:region, iso: 'EU')
    country = FactoryBot.create(:country, name: 'Belgium', iso_3: 'BEL', region: region)
    FactoryBot.create(:country_statistic, country: country, land_area: 50, pa_land_area: 50,
      marine_area: 50, pa_marine_area: 50, percentage_pa_land_cover: 50,
      percentage_pa_marine_cover: 50, polygons_count: 75, points_count: 25)

    get :show, params: { iso: 'EU' }
    cold = assigns(:overview)
    assert_equal 1, cold[:total_countries]
    assert_equal 75, cold[:total_polygons_percentage]
    assert_equal 25, cold[:total_points_percentage]

    country_queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      country_queries << payload[:sql] if payload[:sql].to_s.match?(/\bcountries\b|\bcountry_statistics\b/)
    end
    get :show, params: { iso: 'EU' }
    ActiveSupport::Notifications.unsubscribe(subscriber)

    assert_equal cold, assigns(:overview)
    assert_empty country_queries, "warm region page still queried: #{country_queries.join(', ')}"
  end
end
