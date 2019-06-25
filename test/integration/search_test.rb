# coding: utf-8
require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  test 'Index simple pa works' do
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

    pas = ProtectedArea.without_geometry.includes([
      {:countries_for_index => :region_for_index},
      :sub_locations,
      :designation,
      :iucn_category,
      :governance
    ])
    print JSON.pretty_generate(pas.as_json)
    si = Search::Index.new 'protected_areas', pas
    si.index
    
  end

end
