require 'test_helper'

class ApiTest < ActionDispatch::IntegrationTest
  test 'returns protected_areas filtered by wdpa_id' do
    FactoryGirl.create(:protected_area, wdpa_id: 1, name: 'Manbone')
    FactoryGirl.create(:protected_area, wdpa_id: 2, name: 'Killbear')
    
    get 'api/protected_areas?wdpa_id=1'

    assert_equal 200, response.status

    protected_area = JSON.parse(response.body, symbolize_names: true)
    name = protected_area[:name]

    assert_includes name, 'Manbone'
    refute_includes name, 'Killbear'
  end
end