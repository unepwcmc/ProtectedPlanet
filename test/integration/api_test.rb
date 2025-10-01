require 'test_helper'

class ApiTest < ActionDispatch::IntegrationTest
  test '/api/v3/protected_area, given a WDPA ID, returns the protected
   area' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manboneland', region: region)

    jurisdiction = FactoryGirl.create(:jurisdiction, id: 2, name: 'International')
    iucn_category = FactoryGirl.create(:iucn_category, id: 456, name: 'IA')
    designation = FactoryGirl.create(:designation, id: 654, name: 'National', jurisdiction: jurisdiction)
    governance = FactoryGirl.create(:governance, id: 111, name: 'Bone Man')
    legal_status = FactoryGirl.create(:legal_status, id: 987, name: 'Proposed')

    FactoryGirl.create(:protected_area,
    name: 'Manbone', countries: [country],
    original_name: 'Manboné', iucn_category: iucn_category,
    designation: designation, governance: governance,
    legal_status: legal_status, legal_status_updated_at: time,
    marine: true, site_id: 555999,reported_area: 10.2)

    FactoryGirl.create(:protected_area,
    name: 'Killbear', countries: [country],
    original_name: 'Manboné', iucn_category: iucn_category,
    designation: designation, governance: governance,
    legal_status: legal_status, legal_status_updated_at: time,
    marine: true, site_id: 555333, reported_area: 10.2)

    get '/api/v3/protected_areas/555999'

    assert_response :success

    protected_area = JSON.parse(response.body, symbolize_names: true)
    assert_equal 'Manbone', protected_area[:name]
  end

  test '/api/v3/protected_area, given an invalid WDPA ID, returns a 404
   status' do
    get '/api/v3/protected_areas/666'
    assert_response :missing
  end
end
