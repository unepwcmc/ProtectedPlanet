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

  # A country with OECMs opens on the combined "Protected Areas & OECMs" tab;
  # one without still has only the WDPA tab to open on. Separate countries because
  # build_stats is cached per ISO.
  test '.show defaults to the combined tab only where the country has OECMs' do
    FactoryBot.create(:region, iso: 'GL')
    region = FactoryBot.create(:region)
    plain = FactoryBot.create(:country, name: 'Orange Emirate', iso_3: 'PUM', region: region)
    with_oecms = FactoryBot.create(:country, name: 'Lemon Republic', iso_3: 'LEM', region: region)
    FactoryBot.create(:country_statistic, country: plain)
    FactoryBot.create(:country_statistic,
      country: with_oecms,
      oecms_pa_land_area: 10,
      oecms_pa_marine_area: 5,
      percentage_oecms_pa_land_cover: 1,
      percentage_oecms_pa_marine_cover: 2
    )
    FactoryBot.create(:protected_area, is_oecm: true, countries: [with_oecms])
    seed_cms

    get :show, params: { iso: 'PUM' }
    assert_equal ['wdpa'], assigns(:tabs).map { |tab| tab[:id] }
    assert_equal 'wdpa', assigns(:default_tab_id)

    get :show, params: { iso: 'LEM' }
    assert_equal %w[wdpa wdpa_oecm], assigns(:tabs).map { |tab| tab[:id] }
    assert_equal 'wdpa_oecm', assigns(:default_tab_id)
  end
end
