require 'test_helper'

class PameEvaluationTest < ActiveSupport::TestCase
  test 'basic to_csv with default where clause' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, name: 'Manboneland', region: region)

    iucn_category = FactoryGirl.create(:iucn_category, id: 456, name: 'IA')
    designation = FactoryGirl.create(:designation, id: 654, name: 'National')
    governance = FactoryGirl.create(:governance, id: 654, name: 'Regional')
    marine_realm = Realm.where(name: 'Marine').first_or_create
    pa = FactoryGirl.create(:protected_area,
      name: 'Manbone', countries: [country],
      original_name: 'Manboné', iucn_category: iucn_category,
      designation: designation, marine: true, site_id: 555_999,
      governance: governance, realm: marine_realm, site_type: 'PA',
      the_geom_latitude: 1, the_geom_longitude: 2,
      has_irreplaceability_info: true, has_parcc_info: false)
    FactoryGirl.create(:pame_evaluation,
      name: 'Evaluate Manbone', protected_area: pa, countries: [country])
    # The pame_evaluations_area_xor check constraint requires each evaluation to
    # reference exactly one of a protected area or a parcel, so this one gets its
    # own PA carrying the site_id.
    other_pa = FactoryGirl.create(:protected_area, site_id: 42, countries: [country])
    FactoryGirl.create(:pame_evaluation,
      name: 'Evaluate Thingamy', protected_area: other_pa,
      countries: [country])
    csv_string = PameEvaluation.to_csv('{"_json":[{"name":"method","options":[],"type":"multiple"},{"name":"country","options":[],"type":"multiple"},{"name":"year","options":[],"type":"multiple"}],"controller":"pame","action":"download","pame":{"_json":[{"name":"method","options":[],"type":"multiple"},{"name":"country","options":[],"type":"multiple"},{"name":"year","options":[],"type":"multiple"}]}}')
    assert_equal 3, csv_string.lines.count

    rows = CSV.parse(csv_string.sub(/\A\uFEFF/, ''), headers: true)
    assert_includes rows.headers, 'SITE_TYPE'
    assert_includes rows.headers, 'REALM'
    manbone = rows.find { |r| r['NAME_ENG'] == 'Evaluate Manbone' }
    assert_equal 'PA', manbone['SITE_TYPE']
    assert_equal 'Marine', manbone['REALM']
  end

  test 'to_csv includes evaluations with sites' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, name: 'Manboneland', region: region)

    iucn_category = FactoryGirl.create(:iucn_category, id: 456, name: 'IA')
    designation = FactoryGirl.create(:designation, id: 654, name: 'National')
    governance = FactoryGirl.create(:governance, id: 654, name: 'Regional')
    pa = FactoryGirl.create(:protected_area,
      name: 'Manbone', countries: [country],
      original_name: 'Manboné', iucn_category: iucn_category,
      designation: designation, marine: true, site_id: 555_999,
      governance: governance,
      the_geom_latitude: 1, the_geom_longitude: 2,
      has_irreplaceability_info: true, has_parcc_info: false)
    FactoryGirl.create(:pame_evaluation,
      name: 'Evaluate Manbone', protected_area: pa, countries: [country])
    # See pame_evaluations_area_xor: an evaluation must reference a PA or a parcel.
    other_pa = FactoryGirl.create(:protected_area, site_id: 42, countries: [country])
    FactoryGirl.create(:pame_evaluation,
      name: 'Evaluate Thingamy', protected_area: other_pa,
      countries: [country])
    csv_string = PameEvaluation.to_csv('{"_json":[{"name":"method","options":[],"type":"multiple"},{"name":"country","options":[],"type":"multiple"},{"name":"year","options":[],"type":"multiple"}],"controller":"pame","action":"download","pame":{"_json":[{"name":"method","options":[],"type":"multiple"},{"name":"country","options":[],"type":"multiple"},{"name":"year","options":[],"type":"multiple"}]}}')
    assert_equal 3, csv_string.lines.count
  end
end
