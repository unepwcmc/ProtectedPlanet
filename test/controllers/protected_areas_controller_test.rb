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
    get :show, params: {id: @protected_area.slug}
    assert_response :success
  end

  test '#show is successful even if no jurisdiction is present' do
    designation = FactoryGirl.create(:designation)
    region = FactoryGirl.create(:region)
    country = FactoryGirl.create(:country, region: region)

    protected_area = FactoryGirl.create(
      :protected_area, designation: designation, countries: [country]
    )

    get :show, params: {id: protected_area.wdpa_id}
  end

  test '#show, given a PA that does not exist, renders a 404 page' do
    get :show, params: {id: 'flarglearg'}
    assert_response :missing
  end
end
