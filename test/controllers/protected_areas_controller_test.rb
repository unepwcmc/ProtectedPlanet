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
  end

  test '#show, given a PA that does not exist, renders the 404 page' do
    # PageNotFound is rescued into the styled 404 page in every environment (the
    # StandardError handler stays production-only), so assert the response rather
    # than expecting the exception to propagate.
    get :show, params: {id: 'flarglearg'}
    assert_response :not_found
  end
end
