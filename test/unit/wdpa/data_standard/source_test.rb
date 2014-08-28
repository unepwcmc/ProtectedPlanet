# language
# disclaimer

require 'test_helper'

class TestSourceDataStandard < ActiveSupport::TestCase
  test '.attributes_from_standards_hash returns the correct attribute
   for metadataid' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {metadataid: 1234}
    )

    assert_equal({metadataid: 1234}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for data_title' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {data_title: 'Protected Areas in My House'}
    )

    assert_equal({title: 'Protected Areas in My House'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for resp_party' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {resp_party: 'You'}
    )

    assert_equal({responsible_party: 'You'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for resp_email' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {resp_email: 'you@responsibility.com'}
    )

    assert_equal({responsible_email: 'you@responsibility.com'}, attributes)
  end

  test '.attributes_from_standards_hash returns a Date for the year
   attribute' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {year: 1984}
    )

    assert_kind_of Date, attributes[:year]
    assert_equal   1984, attributes[:year].year
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for char_set' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {char_set: '8-FTU'}
    )

    assert_equal({character_set: '8-FTU'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for ref_system' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {ref_system: 'Spatial Data, yeah?'}
    )

    assert_equal({reference_system: 'Spatial Data, yeah?'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for scale' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {scale: '1:1'}
    )

    assert_equal({scale: '1:1'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for lineage' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {lineage: 'Made up data so I could appear smarter'}
    )

    assert_equal({lineage: 'Made up data so I could appear smarter'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for citation' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {citation: 'Some science mag'}
    )

    assert_equal({citation: 'Some science mag'}, attributes)
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for disclaimer' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {disclaimer: 'The data cannot be used anywhere, for any reason'}
    )

    assert_equal(
      {disclaimer: 'The data cannot be used anywhere, for any reason'},
      attributes
    )
  end

  test '.attributes_from_standards_hash returns the correct attribute
   for language' do
    attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
      {language: 'Esperanto'}
    )

    assert_equal({language: 'Esperanto'}, attributes)
  end

end
