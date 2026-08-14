require 'test_helper'

# Characterization tests for the WDPA portal ProtectedArea relation (create_models path),
# which was 0% covered. It turns a raw portal attribute hash into associated model objects.
# Main-model conversions run against the real test DB (factories exist); the two staging
# conversions (sources / no_take_status) are mocked because staging_* tables aren't loaded
# in the test schema.
class Wdpa::Portal::Relation::ProtectedAreaTest < ActiveSupport::TestCase
  Relation = Wdpa::Portal::Relation::ProtectedArea

  test '#create_models converts relational attributes to model objects and drops non-persisted fields' do
    attrs = {
      'legal_status' => 'Designated',
      'jurisdiction' => 'National',   # relation-only helper, must be removed
      'no_take_area' => 5,            # relation-only helper, must be removed
      'name'         => 'Test PA'     # no converter -> passes through untouched
    }
    result = Relation.new(attrs).create_models

    assert_instance_of LegalStatus, result['legal_status']
    assert_equal 'Designated', result['legal_status'].name
    assert_equal 'Test PA', result['name']
    refute result.key?('jurisdiction'), 'jurisdiction is for_create:false -> removed'
    refute result.key?('no_take_area'), 'no_take_area is for_create:false -> removed'
  end

  test '#remove_fields deletes the columns flagged for_create:false (string and symbol keys)' do
    attrs = { 'no_take_area' => 1, jurisdiction: 'X', 'name' => 'keep' }
    result = Relation.new(attrs).create_models
    refute result.key?('no_take_area')
    refute result.key?(:jurisdiction)
    assert_equal 'keep', result['name']
  end

  test '#countries resolves iso3 codes to Country records and skips unknown ones' do
    can = FactoryBot.create(:country, iso_3: 'CAN')
    usa = FactoryBot.create(:country, iso_3: 'USA')
    result = Relation.new({}).countries(%w[CAN USA ZZZ])
    assert_equal [can, usa], result # ZZZ unknown -> compacted out
  end

  test '#legal_status finds or creates by name (reuses an existing record)' do
    existing = LegalStatus.where(name: 'Proposed').first_or_create
    rel = Relation.new({})
    assert_equal existing, rel.legal_status('Proposed')       # reused
    assert_difference('LegalStatus.count', 1) { rel.legal_status('Brand New Status') } # created
  end

  test '#iucn_category / #governance / #realm first_or_create by name' do
    rel = Relation.new({})
    assert_instance_of IucnCategory, rel.iucn_category('Ia')
    assert_instance_of Governance, rel.governance('Federal')
    assert_instance_of Realm, rel.realm('Terrestrial')
  end

  test '#designation with a jurisdiction creates the Designation linked to that Jurisdiction' do
    rel = Relation.new({ 'jurisdiction' => 'National' })
    designation = rel.designation('National Park')
    assert_instance_of Designation, designation
    assert_equal 'National Park', designation.name
    assert_equal 'National', designation.jurisdiction.name
  end

  test '#designation without a jurisdiction creates the Designation with a nil jurisdiction' do
    # The nullable-jurisdiction case behind the belongs_to_required_by_default opt-out.
    rel = Relation.new({}) # no 'jurisdiction' key
    designation = rel.designation('Wilderness Area')
    assert_instance_of Designation, designation
    assert_nil designation.jurisdiction
  end

  test '#sources maps metadata ids to Staging::Source records and compacts misses' do
    src = mock('staging_source')
    Staging::Source.stubs(:find_by).with(metadataid: 1).returns(src)
    Staging::Source.stubs(:find_by).with(metadataid: 2).returns(nil) # missing -> dropped
    assert_equal [src], Relation.new({}).sources([1, 2])
  end

  test '#sources wraps a single value in an array' do
    src = mock('staging_source')
    Staging::Source.stubs(:find_by).with(metadataid: 7).returns(src)
    assert_equal [src], Relation.new({}).sources(7)
  end

  test '#no_take_status builds a Staging::NoTakeStatus using the no_take_area attribute' do
    created = mock('no_take_status')
    Staging::NoTakeStatus.expects(:create).with({ name: 'Part', area: 42 }).returns(created)
    result = Relation.new({ 'no_take_area' => 42 }).no_take_status('Part')
    assert_equal created, result
  end
end
