require 'test_helper'

class Wdpa::Portal::Utils::ProtectedAreaColumnMapperTest < ActiveSupport::TestCase
  test 'realm_to_marine_type converts valid realm values correctly' do
    assert_equal 0, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('Terrestrial')
    assert_equal 0, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('terrestrial')
    assert_equal 0, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('TERRESTRIAL')

    assert_equal 1, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('Coastal')
    assert_equal 1, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('coastal')
    assert_equal 1, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('COASTAL')

    assert_equal 2, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('Marine')
    assert_equal 2, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('marine')
    assert_equal 2, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('MARINE')
  end

  test 'realm_to_marine_type raises error for invalid values' do
    assert_raises(ArgumentError) do
      Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type(nil)
    end

    assert_raises(ArgumentError) do
      Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('')
    end

    assert_raises(ArgumentError) do
      Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('   ')
    end

    assert_raises(ArgumentError) do
      Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('Invalid')
    end

    assert_raises(ArgumentError) do
      Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('Freshwater')
    end
  end

  test 'realm_is_marine converts valid realm values correctly' do
    assert_equal false, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('Terrestrial')
    assert_equal false, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('terrestrial')
    assert_equal false, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('TERRESTRIAL')

    assert_equal true, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('Coastal')
    assert_equal true, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('coastal')
    assert_equal true, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('COASTAL')

    assert_equal true, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('Marine')
    assert_equal true, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('marine')
    assert_equal true, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('MARINE')
  end

  test 'realm_is_marine raises error for invalid values' do
    assert_raises(ArgumentError) do
      Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine(nil)
    end

    assert_raises(ArgumentError) do
      Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('')
    end

    assert_raises(ArgumentError) do
      Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('   ')
    end

    assert_raises(ArgumentError) do
      Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('Invalid')
    end
  end

  test 'map_portal_to_pp processes realm field correctly' do
    portal_attributes = {
      'realm' => 'Marine',
      'name' => 'Test PA',
      'site_id' => 123
    }

    result = Wdpa::Portal::Utils::ProtectedAreaColumnMapper.map_portal_to_pp(
      portal_attributes,
      'protected_areas',
      Wdpa::Portal::Relation::ProtectedArea
    )

    # Should have realm, marine, and marine_type fields
    assert_equal 'Marine', result[:realm]
    assert_equal true, result[:marine]
    assert_equal 2, result[:marine_type]
    assert_equal 'Test PA', result[:name]
    assert_equal 123, result[:site_id]
  end

  test 'map_portal_to_pp handles empty realm field' do
    portal_attributes = {
      'realm' => '',
      'name' => 'Test PA',
      'site_id' => 123
    }

    assert_raises(ArgumentError) do
      Wdpa::Portal::Utils::ProtectedAreaColumnMapper.map_portal_to_pp(
        portal_attributes,
        'protected_areas',
        Wdpa::Portal::Relation::ProtectedArea
      )
    end
  end

  test 'map_portal_to_pp handles invalid realm field' do
    portal_attributes = {
      'realm' => 'Freshwater',
      'name' => 'Test PA',
      'site_id' => 123
    }

    assert_raises(ArgumentError) do
      Wdpa::Portal::Utils::ProtectedAreaColumnMapper.map_portal_to_pp(
        portal_attributes,
        'protected_areas',
        Wdpa::Portal::Relation::ProtectedArea
      )
    end
  end

  test 'map_portal_to_pp processes other fields normally' do
    portal_attributes = {
      'name' => 'Test PA',
      'site_id' => 123,
      'status' => 'Designated'
    }

    result = Wdpa::Portal::Utils::ProtectedAreaColumnMapper.map_portal_to_pp(
      portal_attributes,
      'protected_areas',
      Wdpa::Portal::Relation::ProtectedArea
    )

    assert_equal 'Test PA', result[:name]
    assert_equal 123, result[:site_id]
    assert_equal 'Designated', result[:status]
  end
end
