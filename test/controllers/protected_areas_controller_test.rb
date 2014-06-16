require 'test_helper'

class ProtectedAreasControllerTest < ActionController::TestCase

  test '#show returns a 200 HTTP code' do
    protected_area = FactoryGirl.create(:protected_area, name: 'Killbear', slug: 'killbear')

    get :show, id: 'killbear'
    assert_response :success
  end

end
