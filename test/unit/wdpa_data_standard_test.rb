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

  test '.attributes_from_standards_hash ignores attributes not in the
   WDPA Standard' do
    attributes = WdpaDataStandard.attributes_from_standards_hash({awesomeness: 'Very Awesome'})
    assert_equal({}, attributes)
  end
end
