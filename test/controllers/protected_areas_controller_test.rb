require 'test_helper'

class ProtectedAreasControllerTest < ActionController::TestCase
  def setup
    @region  = FactoryBot.create(:region, name: 'Killbeurope')
    @country = FactoryBot.create(:country, name: 'Killbearland', region: @region)
    @protected_area = FactoryBot.create(:protected_area, name: 'Killbear', countries: [@country])

    search_mock = mock().tap { |m| m.stubs(:results).returns([]) }
    Search.stubs(:search).returns(search_mock)

    seed_cms
  end

  test '#show returns a 200 HTTP code' do
    get :show, params: {id: @protected_area.site_id}
    assert_response :success
  end

  test '#show counts a visit for a browser' do
    request.user_agent = 'Mozilla/5.0 (Macintosh) AppleWebKit/537.36 Safari/537.36'
    $redis.expects(:zincrby).with(DateTime.now.strftime('%m-%Y'), 1, @protected_area.site_id)

    get :show, params: {id: @protected_area.site_id}
    assert_response :success
  end

  test '#show does not count a visit for a crawler' do
    # The sitemap advertises every /:id page, so a full crawl would otherwise tick
    # every protected area in the popularity counter.
    request.user_agent = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
    $redis.expects(:zincrby).never

    get :show, params: {id: @protected_area.site_id}
    assert_response :success
  end

  test '#show, given a slug, redirects to the search page' do
    # PAs can share a name/slug across different SITE IDs, so slug lookups are
    # redirected to search rather than rendering one arbitrary PA.
    get :show, params: {id: @protected_area.slug}
    assert_redirected_to search_areas_path(search_term: @protected_area.name)
  end

  test '#show is successful even if no jurisdiction is present' do
    designation = FactoryBot.create(:designation)
    region = FactoryBot.create(:region)
    country = FactoryBot.create(:country, region: region)

    protected_area = FactoryBot.create(
      :protected_area, designation: designation, countries: [country]
    )

    get :show, params: {id: protected_area.site_id}

    # Without this the test could only fail by raising -- minitest reported it as
    # "missing assertions".
    assert_response :success
  end

  test '#show, given a PA that does not exist, renders the 404 page' do
    # PageNotFound is rescued into the styled 404 page in every environment (the
    # StandardError handler stays production-only), so assert the response rather
    # than expecting the exception to propagate.
    get :show, params: {id: 'flarglearg'}
    assert_response :not_found
  end

  test '#show, given a non-HTML format, renders the HTML 404 page rather than blowing up' do
    # /sitemaps.xml matches neither sitemap route (both declare format: false) and
    # falls through to the catch-all `get '/:id'`, which parses it as id "sitemaps"
    # + format "xml". render_error_page pins formats to :html because error_page
    # only exists as .html.erb -- without that pin the rescue_from handler raised
    # ActionView::MissingTemplate and the 404 came back as a 500.
    get :show, params: { id: 'sitemaps', format: 'xml' }

    assert_response :not_found
    assert_equal 'text/html', response.media_type
  end
end
