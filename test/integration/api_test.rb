require 'test_helper'

class ApiTest < ActionDispatch::IntegrationTest
  test 'returns protected_areas filtered by wdpa_id' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manboneland', region: region)
    sub_location = FactoryGirl.create(:sub_location, english_name: 'Manboneland City')

    jurisdiction = FactoryGirl.create(:jurisdiction, id: 2, name: 'International')
    iucn_category = FactoryGirl.create(:iucn_category, id: 456, name: 'IA')
    designation = FactoryGirl.create(:designation, id: 654, name: 'National', jurisdiction: jurisdiction)
    governance = FactoryGirl.create(:governance, id: 111, name: 'Bone Man')
    legal_status = FactoryGirl.create(:legal_status, id: 987, name: 'Proposed')

    FactoryGirl.create(:protected_area,
    name: 'Manbone', countries: [country], sub_locations: [sub_location],
    original_name: 'Manboné', iucn_category: iucn_category,
    designation: designation, governance: governance,
    legal_status: legal_status, legal_status_updated_at: time,
    marine: true, wdpa_id: 555999,reported_area: 10.2)

    FactoryGirl.create(:protected_area,
    name: 'Killbear', countries: [country], sub_locations: [sub_location],
    original_name: 'Manboné', iucn_category: iucn_category,
    designation: designation, governance: governance,
    legal_status: legal_status, legal_status_updated_at: time,
    marine: true, wdpa_id: 555333, reported_area: 10.2)
    
    get 'api/protected_areas?wdpa_id=555999'

    assert_equal 200, response.status

    protected_area = JSON.parse(response.body, symbolize_names: true)

    name = protected_area[:name]
    legal_status = protected_area[:legal_status][:name]

    assert_includes name, 'Manbone'
    refute_includes name, 'Killbear'
  end
end