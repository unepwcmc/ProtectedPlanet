require 'test_helper'

class ProtectedAreaShowTest < ActionDispatch::IntegrationTest
  def setup
    @region  = FactoryGirl.create(:region, name: 'Killbeurope')
    @country = FactoryGirl.create(:country, name: 'Killbearland', region: @region)
    @protected_area = FactoryGirl.create(
      :protected_area, name: 'Killbear', slug: 'killbear', countries: [@country]
    )

    search_mock = mock.tap { |m| m.stubs(:results).returns([]) }
    Search.stubs(:search).returns(search_mock)

    seed_cms
  end

  test 'redirects a slug lookup to the search page for that name' do
    # A slug hit intentionally redirects to search (see ProtectedAreasController#show;
    # guards against duplicate slugs across SITE IDs). Assert the redirect itself --
    # Rails 7.1 dropped the default "You are being redirected" HTML body, so matching
    # the name in @response.body (as this test used to) no longer works.
    get "/#{@protected_area.slug}"
    assert_response :redirect
    assert_match(/search_term=Killbear/, @response.location)
  end

  test 'renders the Protected Area name given a SITE ID' do
    get "/#{@protected_area.site_id}"
    assert_match(/Killbear/, @response.body)
  end
end
