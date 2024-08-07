# coding: utf-8
require 'test_helper'

class PameEvaluationTest < ActiveSupport::TestCase


  test "basic to_csv with default where clause" do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, name: 'Manboneland', region: region)
    sub_location = FactoryGirl.create(:sub_location, english_name: 'Manboneland City')
    
    iucn_category = FactoryGirl.create(:iucn_category, id: 456, name: 'IA')
    designation = FactoryGirl.create(:designation, id: 654, name: 'National')
    governance = FactoryGirl.create(:governance, id: 654, name: 'Regional')
    pa = FactoryGirl.create(:protected_area,
      name: 'Manbone', countries: [country], sub_locations: [sub_location],
      original_name: 'Manboné', iucn_category: iucn_category,
      designation: designation, marine: true, wdpa_id: 555999,
      governance: governance,
      the_geom_latitude: 1, the_geom_longitude: 2,
      has_irreplaceability_info: true, has_parcc_info: false
    )
    pe = FactoryGirl.create(:pame_evaluation,
                            name: 'Evaluate Manbone', protected_area: pa, countries: [country])
    # evaluation with no pa and restricted
    pe = FactoryGirl.create(:pame_evaluation,
                            name: 'Evaluate Thingamy', wdpa_id: 42,
                            countries: [country])
    csv_string = PameEvaluation.to_csv("{\"_json\":[{\"name\":\"methodology\",\"options\":[],\"type\":\"multiple\"},{\"name\":\"iso3\",\"options\":[],\"type\":\"multiple\"},{\"name\":\"year\",\"options\":[],\"type\":\"multiple\"}],\"controller\":\"pame\",\"action\":\"download\",\"pame\":{\"_json\":[{\"name\":\"methodology\",\"options\":[],\"type\":\"multiple\"},{\"name\":\"iso3\",\"options\":[],\"type\":\"multiple\"},{\"name\":\"year\",\"options\":[],\"type\":\"multiple\"}]}}")
    assert_equal 3, csv_string.lines.count
  end


  test "restricted excluded in to_csv with default where clause" do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, name: 'Manboneland', region: region)
    sub_location = FactoryGirl.create(:sub_location, english_name: 'Manboneland City')
    
    iucn_category = FactoryGirl.create(:iucn_category, id: 456, name: 'IA')
    designation = FactoryGirl.create(:designation, id: 654, name: 'National')
    governance = FactoryGirl.create(:governance, id: 654, name: 'Regional')
    pa = FactoryGirl.create(:protected_area,
      name: 'Manbone', countries: [country], sub_locations: [sub_location],
      original_name: 'Manboné', iucn_category: iucn_category,
      designation: designation, marine: true, wdpa_id: 555999,
      governance: governance,
      the_geom_latitude: 1, the_geom_longitude: 2,
      has_irreplaceability_info: true, has_parcc_info: false
    )
    pe = FactoryGirl.create(:pame_evaluation,
                            name: 'Evaluate Manbone', protected_area: pa, countries: [country], restricted: true)
    # evaluation with no pa and restricted
    pe = FactoryGirl.create(:pame_evaluation,
                            name: 'Evaluate Thingamy', wdpa_id: 42, restricted: true,
                            countries: [country])
    csv_string = PameEvaluation.to_csv("{\"_json\":[{\"name\":\"methodology\",\"options\":[],\"type\":\"multiple\"},{\"name\":\"iso3\",\"options\":[],\"type\":\"multiple\"},{\"name\":\"year\",\"options\":[],\"type\":\"multiple\"}],\"controller\":\"pame\",\"action\":\"download\",\"pame\":{\"_json\":[{\"name\":\"methodology\",\"options\":[],\"type\":\"multiple\"},{\"name\":\"iso3\",\"options\":[],\"type\":\"multiple\"},{\"name\":\"year\",\"options\":[],\"type\":\"multiple\"}]}}")
    assert_equal 1, csv_string.lines.count
  end

  
end
