require 'test_helper'

class CountryControllerTest < ActionController::TestCase
  test '.show returns a 200 HTTP code' do
    FactoryBot.create(:region, iso: 'GL')

    region = FactoryBot.create(:region)

    country = FactoryBot.create(:country, name: 'Orange Emirate', iso_3: 'PUM', region: region)

    FactoryBot.create(:country_statistic,
      country: country,
      pa_area: 100,
      percentage_pa_cover: 50,
      percentage_pa_land_cover: 50,
      percentage_pa_eez_cover: 50,
      percentage_pa_ts_cover: 50,
      polygons_count: 100,
      points_count: 100
    )

    FactoryBot.create(:pame_statistic, country: country)

    seed_cms

    get :show, params: {iso: 'PUM'}
    assert_response :success
  end

  # /country/:iso/pdf is the page the Puppeteer rasterizer captures, so an empty
  # body means a blank PDF. The action used to be nothing but `@for_pdf = true`
  # with no app/views/country/pdf template, and Rails answers "204 No Content"
  # when an action renders nothing -- the endpoint looked alive (2xx) while
  # serving nothing at all. Assert on the body, not just the status.
  test '.pdf renders the country page rather than an empty 204' do
    FactoryBot.create(:region, iso: 'GL')
    region = FactoryBot.create(:region)
    country = FactoryBot.create(:country, name: 'Orange Emirate', iso_3: 'PUM', region: region)

    FactoryBot.create(:country_statistic,
      country: country,
      pa_area: 100,
      percentage_pa_cover: 50,
      percentage_pa_land_cover: 50,
      percentage_pa_eez_cover: 50,
      percentage_pa_ts_cover: 50,
      polygons_count: 100,
      points_count: 100
    )
    FactoryBot.create(:pame_statistic, country: country)
    seed_cms

    get :pdf, params: { iso: 'PUM' }

    assert_response :success
    assert_not_equal 204, response.status, 'a 204 means no template rendered -- the PDF would be blank'
    assert_template :show, 'the PDF view must reuse the country page, not a divergent copy'
    assert response.body.present?
    assert assigns(:for_pdf), 'the layout strips chrome based on @for_pdf'
    # These come from before_actions that were :show-only and therefore skipped.
    assert_not_nil assigns(:stats_data)
    assert_not_nil assigns(:tabs)
  end
end
