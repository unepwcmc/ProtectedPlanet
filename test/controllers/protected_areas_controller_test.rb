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
end
