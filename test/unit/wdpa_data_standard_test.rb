require 'test_helper'

class TestWdpaDataStandard < ActiveSupport::TestCase
  test '.attributes_from_standards_hash returns the correct attribute
   for WDPA ID' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({wdpaid: 1234})
    assert_equal({wdpa_id: 1234}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for WDPA Parent ID' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({wdpa_pid: 1234})
    assert_equal({wdpa_parent_id: 1234}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for name' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({name: 'Manbone Island'})
    assert_equal({name: 'Manbone Island'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for original_name' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({orig_name: 'Manbone Island'})
    assert_equal({original_name: 'Manbone Island'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   when marine is false' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({marine: '0'})
    assert_equal({marine: false}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   when marine is true' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({marine: '1'})
    assert_equal({marine: true}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for reported_marine_area' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({rep_m_area: 14.5643})
    assert_equal({reported_marine_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for reported_area' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({rep_area: 14.5643})
    assert_equal({reported_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for gis_marine_area' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({gis_m_area: 14.5643})
    assert_equal({gis_marine_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for gis_area' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({gis_area: 14.5643})
    assert_equal({gis_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for int_crit' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({int_crit: '(ii)(iv)'})
    assert_equal({international_criteria: '(ii)(iv)'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for no_take' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({no_take: 'All'})
    assert_equal({no_take: 'All'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for no_tk_area' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({no_tk_area: 0.4})
    assert_equal({no_take_area: 0.4}, attributes)
  end

  test '.attributes_from_standards_hash returns Country models for given
   ISO codes' do
    FactoryGirl.create(:country, iso_3: 'NOR', name: 'Norway')
    FactoryGirl.create(:country, iso_3: 'GTM', name: 'Guatemala')

    attributes = Wdpa::DataStandard.attributes_from_standards_hash({iso3: 'NOR, GTM,'})

    assert_equal 2, attributes[:countries].length,
      "Expected two Country models to be returned"

    assert_kind_of Country, attributes[:countries].first
    assert_equal   "Norway", attributes[:countries].first.name

    assert_kind_of Country, attributes[:countries].second
    assert_equal   "Guatemala", attributes[:countries].second.name
  end

  test '.attributes_from_standards_hash returns SubLocation models for given
   ISO codes' do
    FactoryGirl.create(:sub_location, iso: 'AT-NOR', english_name: 'Norway')
    FactoryGirl.create(:sub_location, iso: 'AT-AT', english_name: 'Galaxy')

    attributes = Wdpa::DataStandard.attributes_from_standards_hash({sub_loc: 'AT-AT, AT-NOR,'})

    assert_equal 2, attributes[:sub_locations].length,
      "Expected two SubLocation models to be returned"

    assert_kind_of SubLocation, attributes[:sub_locations].first
    assert_equal   "AT-AT", attributes[:sub_locations].first.iso

    assert_kind_of SubLocation, attributes[:sub_locations].second
    assert_equal   "AT-NOR", attributes[:sub_locations].second.iso
  end

  test '.attributes_from_standards_hash returns an empty array if the
   sub locations do not exist' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({sub_loc: 'AT-AT'})

    assert_equal 0, attributes[:sub_locations].length,
      "Expected no SubLocation models to be returned"
  end

  test '.attributes_from_standards_hash returns LegalStatus models for a
   given legal status' do
    status_name = "It's legal, honest"
    FactoryGirl.create(:legal_status, name: status_name)

    attributes = Wdpa::DataStandard.attributes_from_standards_hash({status: status_name})

    assert_kind_of LegalStatus, attributes[:legal_status]
    assert_equal   status_name, attributes[:legal_status].name
  end

  test '.attributes_from_standards_hash creates a new LegalStatus if one
   does not already exist' do
    skip
  end

  test '.attributes_from_standards_hash returns a Date for a given legal
   status change year' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({status_yr: 1984})

    assert_kind_of Date, attributes[:legal_status_updated_at]
    assert_equal   1984, attributes[:legal_status_updated_at].year
  end

  test '.attributes_from_standards_hash returns an IucnCategory for a
   given IUCN category' do
    category_name = 'Extinct'
    FactoryGirl.create(:iucn_category, name: category_name)

    attributes = Wdpa::DataStandard.attributes_from_standards_hash({iucn_cat: category_name})

    assert_kind_of IucnCategory, attributes[:iucn_category]
    assert_equal   category_name, attributes[:iucn_category].name
  end

  test '.attributes_from_standards_hash returns a Governance for a given
   governance type' do
    governance_name = 'Ministry of Ministries'
    FactoryGirl.create(:governance, name: governance_name)

    attributes = Wdpa::DataStandard.attributes_from_standards_hash({gov_type: governance_name})

    assert_kind_of Governance, attributes[:governance]
    assert_equal   governance_name, attributes[:governance].name
  end

  test '.attributes_from_standards_hash returns a ManagementAuthority for a given
   management authority' do
    management_name = 'Authority of Authorities'
    FactoryGirl.create(:management_authority, name: management_name)

    attributes = Wdpa::DataStandard.attributes_from_standards_hash({mang_auth: management_name})

    assert_kind_of ManagementAuthority, attributes[:management_authority]
    assert_equal   management_name, attributes[:management_authority].name
  end

  test '.attributes_from_standards_hash creates a new ManagementAuthority if one
   does not already exist' do
    skip
  end

  test '.attributes_from_standards_hash returns a Designation for a given
   designation and designation type' do
    designation = "Sites of Special Importance"
    designation_type = "Universal"

    jurisdiction = FactoryGirl.create(:jurisdiction, name: designation_type)
    FactoryGirl.create(:designation, name: designation, jurisdiction: jurisdiction)

    attributes = Wdpa::DataStandard.attributes_from_standards_hash({
      desig: designation,
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
    skip
  end

  test '.attributes_from_standards_hash ignores attributes not in the
   WDPA Standard' do
    attributes = Wdpa::DataStandard.attributes_from_standards_hash({awesomeness: 'Very Awesome'})
    assert_equal({}, attributes)
  end
end
