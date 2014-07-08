require 'test_helper'

class ProtectedAreasControllerTest < ActionController::TestCase
  def setup
    @region  = FactoryGirl.create(:region, name: 'Killbeurope')
    @country = FactoryGirl.create(:country, name: 'Killbearland', region: @region)
    @protected_area = FactoryGirl.create(:protected_area, name: 'Killbear', slug: 'killbear', countries: [@country])
  end

  test '#show returns a 200 HTTP code' do
    get :show, id: 'killbear'
    assert_response :success
  end

  test '#show is successful even if no jurisdiction is present' do
    designation = FactoryGirl.create(:designation)
    region = FactoryGirl.create(:region)
    country = FactoryGirl.create(:country, region: region)

    @protected_area = FactoryGirl.create(
      :protected_area, designation: designation, countries: [country]
    )

    get :show, id: @protected_area.wdpa_id
  end
end
