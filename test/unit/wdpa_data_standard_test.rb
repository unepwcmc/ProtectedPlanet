require 'test_helper'

class TestWdpaDataStandard < ActiveSupport::TestCase
  test '.attributes_from_standards_hash returns the correct attribute
   for WDPA ID' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({wdpaid: 1234})
    assert_equal({wdpa_id: 1234}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for WDPA Parent ID' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({wdpa_pid: 1234})
    assert_equal({wdpa_parent_id: 1234}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for name' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({name: 'Manbone Island'})
    assert_equal({name: 'Manbone Island'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for original_name' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({orig_name: 'Manbone Island'})
    assert_equal({original_name: 'Manbone Island'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   when marine is false' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({marine: '0'})
    assert_equal({marine: false}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   when marine is true' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({marine: '1'})
    assert_equal({marine: true}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for reported_marine_area' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({rep_m_area: 14.5643})
    assert_equal({reported_marine_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for reported_area' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({rep_area: 14.5643})
    assert_equal({reported_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for gis_marine_area' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({gis_m_area: 14.5643})
    assert_equal({gis_marine_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for gis_area' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({gis_area: 14.5643})
    assert_equal({gis_area: 14.5643}, attributes)
  end

  test '.attributes_from_standards_hash returns Country models for given
   ISO codes' do
    FactoryGirl.create(:country, iso_3: 'NOR', name: 'Norway')
    FactoryGirl.create(:country, iso_3: 'GTM', name: 'Guatemala')

    attributes = WdpaDataStandard.attributes_from_standards_hash({iso3: 'NOR, GTM,'})

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

    attributes = WdpaDataStandard.attributes_from_standards_hash({sub_loc: 'AT-AT, AT-NOR,'})

    assert_equal 2, attributes[:sub_locations].length,
      "Expected two SubLocation models to be returned"

    assert_kind_of SubLocation, attributes[:sub_locations].first
    assert_equal   "AT-AT", attributes[:sub_locations].first.iso

    assert_kind_of SubLocation, attributes[:sub_locations].second
    assert_equal   "AT-NOR", attributes[:sub_locations].second.iso
  end

  test '.attributes_from_standards_hash returns LegalStatus models for a
   given legal status' do
    status_name = "It's legal, honest"
    FactoryGirl.create(:legal_status, name: status_name)

    attributes = WdpaDataStandard.attributes_from_standards_hash({status: status_name})

    assert_kind_of LegalStatus, attributes[:legal_status]
    assert_equal   status_name, attributes[:legal_status].name
  end

  test '.attributes_from_standards_hash returns a Date for a given legal
   status change year' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({status_yr: '1984'})

    assert_kind_of Date, attributes[:legal_status_updated_at]
    assert_equal   1984, attributes[:legal_status_updated_at].year
  end

  test '.attributes_from_standards_hash ignores attributes not in the
   WDPA Standard' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({awesomeness: 'Very Awesome'})
    assert_equal({}, attributes)
  end
end
