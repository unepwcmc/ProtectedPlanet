require 'test_helper'

class TestWdpaParcelDataStandard < ActiveSupport::TestCase
  test '.attributes_from_standards_hash returns the correct attribute
   for WDPA ID' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({wdpaid: 1234})
    assert_equal({wdpa_id: 1234}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for WDPA Parent ID' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({site_pid: "1234_A"})
    assert_equal({site_pid: "1234_A"}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for name' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({name: 'Manbone Island'})

    assert_not_nil attributes[:name]
    assert_equal   'Manbone Island', attributes[:name]
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for original_name' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({orig_name: 'Manbone Island'})
    assert_equal({original_name: 'Manbone Island'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   when marine is false' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({marine: '0'})
    assert_equal({marine: false}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   when marine is true when coastal' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({marine: '1'})
    assert_equal({marine: true}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   when marine is true' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({marine: '2'})
    assert_equal({marine: true}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   when is_oecm is false' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({pa_def: '1'})
    assert_equal({is_oecm: false}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   when is_oecm is true' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({pa_def: '0'})
    assert_equal({is_oecm: true}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for reported_marine_area' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({rep_m_area: 14.5643})
    assert_equal({reported_marine_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for reported_area' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({rep_area: 14.5643})
    assert_equal({reported_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for gis_marine_area' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({gis_m_area: 14.5643})
    assert_equal({gis_marine_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for gis_area' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({gis_area: 14.5643})
    assert_equal({gis_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for int_crit' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({int_crit: '(ii)(iv)'})
    assert_equal({international_criteria: '(ii)(iv)'}, attributes)
  end

  test '.attributes_from_standards_hash returns a NoTakeStatus model for given
   no_take value' do
    status = "NO TAKE"
    area   = 153.6

    FactoryGirl.create(:no_take_status, name: status, area: area)

    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({
      no_take: status,
      no_tk_area: area
    })

    assert_kind_of NoTakeStatus, attributes[:no_take_status]
    assert_equal   status, attributes[:no_take_status].name
    assert_equal   area, attributes[:no_take_status].area

    assert_nil attributes[:no_take_area], "Expected no_take_area to not be returned"
  end

  test '.attributes_from_standards_hash returns Country models for given
   ISO codes' do
    norway = FactoryGirl.create(:country, iso_3: 'NOR', name: 'Norway')
    guatemala = FactoryGirl.create(:country, iso_3: 'GTM', name: 'Guatemala')

    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({iso3: 'NOR; GTM;'})

    assert_equal 2, attributes[:countries].length,
      "Expected two Country models to be returned"

    assert_kind_of Country, attributes[:countries].first
    assert_equal   norway.id, attributes[:countries].first.id

    assert_kind_of Country, attributes[:countries].second
    assert_equal   guatemala.id, attributes[:countries].second.id
  end

  test '.attributes_from_standards_hash returns an empty array if the
   countries do not exist' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({iso3: 'NOR'})

    assert_equal 0, attributes[:countries].length,
      "Expected no Country models to be returned"
  end

  test '.attributes_from_standards_hash returns SubLocation models for given
   ISO codes' do
    FactoryGirl.create(:sub_location, iso: 'AT-NOR', english_name: 'Norway')
    FactoryGirl.create(:sub_location, iso: 'AT-AT', english_name: 'Galaxy')

    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({sub_loc: 'AT-AT; AT-NOR;'})

    assert_equal 2, attributes[:sub_locations].length,
      "Expected two SubLocation models to be returned"

    assert_kind_of SubLocation, attributes[:sub_locations].first
    assert_equal   "AT-AT", attributes[:sub_locations].first.iso

    assert_kind_of SubLocation, attributes[:sub_locations].second
    assert_equal   "AT-NOR", attributes[:sub_locations].second.iso
  end

  test '.attributes_from_standards_hash returns an empty array if the
   sub locations do not exist' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({sub_loc: 'AT-AT'})

    assert_equal 0, attributes[:sub_locations].length,
      "Expected no SubLocation models to be returned"
  end

  test '.attributes_from_standards_hash returns LegalStatus models for a
   given legal status' do
    status_name = "It's legal, honest"
    FactoryGirl.create(:legal_status, name: status_name)

    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({status: status_name})

    assert_kind_of LegalStatus, attributes[:legal_status]
    assert_equal   status_name, attributes[:legal_status].name
  end

  test '.attributes_from_standards_hash creates a new LegalStatus if one
   does not already exist' do
    status_name = "It might be legal, who knows"
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({status: status_name})

    assert_kind_of LegalStatus, attributes[:legal_status]
    assert_equal   status_name, attributes[:legal_status].name
  end

  test '.attributes_from_standards_hash returns a Date for a given legal
   status change year' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({status_yr: 1984})

    assert_kind_of Date, attributes[:legal_status_updated_at]
    assert_equal   1984, attributes[:legal_status_updated_at].year
  end

  test '.attributes_from_standards_hash returns a valid Date that can be
    stored in Rails for a given legal status change year' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({status_yr: 0})

    protected_area = FactoryGirl.create(:protected_area)
    protected_area.legal_status_updated_at = attributes[:legal_status_updated_at]

    assert protected_area.save
    assert_equal 0, protected_area.errors.to_a.count
  end

  test '.attributes_from_standards_hash returns an IucnCategory for a
   given IUCN category' do
    category_name = 'Extinct'
    FactoryGirl.create(:iucn_category, name: category_name)

    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({iucn_cat: category_name})

    assert_kind_of IucnCategory, attributes[:iucn_category]
    assert_equal   category_name, attributes[:iucn_category].name
  end

  test '.attributes_from_standards_hash returns a Governance for a given
   governance type' do
    governance_name = 'Ministry of Ministries'
    FactoryGirl.create(:governance, name: governance_name)

    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({gov_type: governance_name})

    assert_kind_of Governance, attributes[:governance]
    assert_equal   governance_name, attributes[:governance].name
  end

  test '.attributes_from_standards_hash returns a ManagementAuthority for a given
   management authority' do
    management_name = 'Authority of Authorities'
    FactoryGirl.create(:management_authority, name: management_name)

    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({mang_auth: management_name})

    assert_kind_of ManagementAuthority, attributes[:management_authority]
    assert_equal   management_name, attributes[:management_authority].name
  end

  test '.attributes_from_standards_hash returns the correct attribute for a
   management plan' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({mang_plan: 'An plan'})
    assert_equal({management_plan: 'An plan'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute for a owner type' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({own_type: 'An owner'})
    assert_equal({owner_type: 'An owner'}, attributes)
  end

  test '.attributes_from_standards_hash creates a new ManagementAuthority if one
   does not already exist' do
    authority = 'A new authority in town'
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({mang_auth: authority})

    assert_kind_of ManagementAuthority, attributes[:management_authority]
    assert_equal   authority, attributes[:management_authority].name
  end

  test '.attributes_from_standards_hash returns a Designation for a given
   designation and designation type' do
    designation = "Sites of Special Importance"
    designation_type = "Universal"

    jurisdiction = FactoryGirl.create(:jurisdiction, name: designation_type)
    FactoryGirl.create(:designation, name: designation, jurisdiction: jurisdiction)

    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({
      desig_eng: designation,
      desig_type: designation_type
    })

    assert_kind_of Designation, attributes[:designation]
    assert_equal   designation, attributes[:designation].name

    assert_kind_of Jurisdiction, attributes[:designation].jurisdiction
    assert_equal   designation_type, attributes[:designation].jurisdiction.name

    assert_nil attributes[:jurisdiction], "Expected jurisdiction to not be returned"
  end

  test '.attributes_from_standards_hash creates a new Designation if one
   does not already exist' do
    designation = "Sites of Special Importance"
    designation_type = "Universal"

    FactoryGirl.create(:jurisdiction, name: designation_type)

    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({
      desig_eng: designation,
      desig_type: designation_type
    })

    assert_kind_of Designation, attributes[:designation]
    assert_equal   designation, attributes[:designation].name

    assert_kind_of Jurisdiction, attributes[:designation].jurisdiction
    assert_equal   designation_type, attributes[:designation].jurisdiction.name
  end

  test '.attributes_from_standards_hash ignores attributes not in the
   WDPA Standard' do
    attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash({awesomeness: 'Very Awesome'})
    assert_equal({}, attributes)
  end

  test '#standard_attributes returns the pre-defined WDPA standard attributes' do
    expected_attributes = Wdpa::ParcelDataStandard::STANDARD_ATTRIBUTES
    assert_equal expected_attributes, Wdpa::ParcelDataStandard.standard_attributes
  end

  test '#standardise_table_name converts WDPA Geodatabase table names in
   to consistent names' do
    standardised_name = Wdpa::ParcelDataStandard.standardise_table_name 'wdpapoly_june2014'
    assert_equal 'standard_polygons', standardised_name

    standardised_name = Wdpa::ParcelDataStandard.standardise_table_name 'wdpapoint_june2014'
    assert_equal 'standard_points', standardised_name
  end

end
