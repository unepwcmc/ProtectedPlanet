require 'test_helper'

class ProtectedAreasControllerTest < ActionController::TestCase
  def setup
    @region  = FactoryGirl.create(:region, name: 'Killbeurope')
    @country = FactoryGirl.create(:country, name: 'Killbearland', region: @region)
    @protected_area = FactoryGirl.create(:protected_area, name: 'Killbear', countries: [@country])

    search_mock = mock().tap { |m| m.stubs(:results).returns([]) }
    Search.stubs(:search).returns(search_mock)

    seed_cms
  end

  test '#show returns a 200 HTTP code' do
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
    designation = FactoryGirl.create(:designation)
    region = FactoryGirl.create(:region)
    country = FactoryGirl.create(:country, region: region)

    protected_area = FactoryGirl.create(
      :protected_area, designation: designation, countries: [country]
    )

    get :show, params: {id: protected_area.site_id}
  end

  test '#show, given a PA that does not exist, raises PageNotFound' do
    # ApplicationController only rescues PageNotFound into a rendered 404 page in
    # production, so in the test environment the exception propagates.
    assert_raises(ApplicationController::PageNotFound) do
      get :show, params: {id: 'flarglearg'}
    end
  end
end
