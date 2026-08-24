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

  # The country page IS the page the Puppeteer rasterizer captures, so an empty body
  # means a blank PDF. There used to be a dedicated /country/:iso/pdf action that was
  # nothing but `@for_pdf = true` with no template, and Rails answers "204 No Content"
  # when an action renders nothing -- the endpoint looked alive (2xx) while serving
  # nothing at all.
  #
  # That action and its route are now gone. Download::Generators::Pdf builds
  # `{'action' => :show, 'for_pdf' => true}` and rasterizes the ordinary country page
  # instead, so this asserts the same thing against the path that is actually used:
  # a real body, the show template, and @for_pdf set so the layout strips the chrome.
  test 'the country page renders a real body when requested for PDF export' do
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

    get :show, params: { iso: 'PUM', for_pdf: true }

    assert_response :success
    assert_not_equal 204, response.status, 'a 204 means no template rendered -- the PDF would be blank'
    assert_template :show
    assert response.body.present?
    assert assigns(:for_pdf), 'the layout strips chrome based on @for_pdf'
    assert_not_nil assigns(:stats_data)
    assert_not_nil assigns(:tabs)
  end
end
