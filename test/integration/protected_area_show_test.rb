require 'test_helper'

class ProtectedAreaShowTest < ActionDispatch::IntegrationTest

  test "renders the Protected Area name" do
    protected_area = FactoryGirl.create(:protected_area, name: 'Killbear', slug: 'killbear')

    get '/killbear'
    assert_match /Killbear/, @response.body
  end
end
