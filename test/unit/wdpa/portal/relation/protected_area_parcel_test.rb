require 'test_helper'

# ProtectedAreaParcel relation is a near-copy of the ProtectedArea relation (same
# create_models dispatch + converters). Compact characterization of the shared path;
# see protected_area_test.rb for the fuller matrix.
class Wdpa::Portal::Relation::ProtectedAreaParcelTest < ActiveSupport::TestCase
  Relation = Wdpa::Portal::Relation::ProtectedAreaParcel

  test '#create_models converts relational attributes and drops non-persisted fields' do
    attrs = { 'legal_status' => 'Designated', 'jurisdiction' => 'National', 'no_take_area' => 3, 'name' => 'Parcel' }
    result = Relation.new(attrs).create_models
    assert_instance_of LegalStatus, result['legal_status']
    assert_equal 'Parcel', result['name']
    refute result.key?('jurisdiction')
    refute result.key?('no_take_area')
  end

  test '#countries resolves iso3 codes and skips unknown ones' do
    can = FactoryBot.create(:country, iso_3: 'CAN')
    assert_equal [can], Relation.new({}).countries(%w[CAN ZZZ])
  end

  test '#designation without a jurisdiction yields a nil jurisdiction' do
    designation = Relation.new({}).designation('Wilderness Area')
    assert_instance_of Designation, designation
    assert_nil designation.jurisdiction
  end
end
