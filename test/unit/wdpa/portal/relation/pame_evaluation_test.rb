require 'test_helper'

# Characterization for the PAME evaluation relation (was 0%). It resolves a PAME row's
# site_id/site_pid to a staging ProtectedArea or ProtectedAreaParcel, derives the name,
# and links method/source. Staging::* + PameMethod are mocked (staging tables aren't in
# the test schema).
class Wdpa::Portal::Relation::PameEvaluationTest < ActiveSupport::TestCase
  Relation = Wdpa::Portal::Relation::PameEvaluation

  test '#create_models resolves the protected area by site_id when no parcel matches' do
    pa = mock('staging_pa'); pa.stubs(:name).returns('Yellowstone')
    Staging::ProtectedAreaParcel.stubs(:find_by).returns(nil)
    Staging::ProtectedArea.stubs(:find_by).with(site_id: 100).returns(pa)
    method_obj = mock('pame_method')
    PameMethod.stubs(:find_or_create_by!).with(name: 'RAPPAM').returns(method_obj)
    psource = mock('pame_source')
    Staging::PameSource.stubs(:find_by).with(id: 55).returns(psource)

    result = Relation.new({ 'site_id' => 100, 'method' => 'RAPPAM', 'eff_metaid' => 55 }).create_models

    assert_equal pa, result[:pa]
    a = result[:attributes_for_create]
    assert_equal '100', a['site_pid'], 'site_pid defaults from site_id'
    assert_equal pa, a['protected_area']
    assert_nil a['protected_area_parcel']
    assert_equal 'Yellowstone', a['name']
    assert_equal method_obj, a['pame_method']
    assert_equal psource, a['pame_source']
  end

  test '#create_models prefers a matching parcel over the protected area, and nils method/source when absent' do
    parcel = mock('parcel'); parcel.stubs(:name).returns('Parcel A')
    Staging::ProtectedAreaParcel.stubs(:find_by).with(site_id: 1, site_pid: '1_1').returns(parcel)

    result = Relation.new({ 'site_id' => 1, 'site_pid' => '1_1' }).create_models

    assert_equal parcel, result[:pa]
    a = result[:attributes_for_create]
    assert_equal parcel, a['protected_area_parcel']
    assert_nil a['protected_area'] # short-circuited: parcel found
    assert_equal 'Parcel A', a['name']
    assert_nil a['pame_method']
    assert_nil a['pame_source']
  end
end
