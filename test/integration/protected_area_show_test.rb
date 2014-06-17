require 'test_helper'

class ProtectedAreaShowTest < ActionDispatch::IntegrationTest

  test 'renders the Protected Area name' do
    protected_area = FactoryGirl.create(:protected_area, name: 'Killbear', slug: 'killbear')

    get '/killbear'
    assert_match /Killbear/, @response.body
  end

  test 'renders the Protected Area name given a WDPA ID' do
    protected_area = FactoryGirl.create(:protected_area, wdpa_id: 1234, name: 'Killbear')

    get '/1234'
    assert_match /Killbear/, @response.body
  end
end
