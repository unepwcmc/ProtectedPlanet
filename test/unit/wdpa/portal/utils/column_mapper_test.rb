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

  test 'realm_to_marine_type returns terrestrial (0) for invalid values' do
    assert_equal 0, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type(nil)
    assert_equal 0, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('')
    assert_equal 0, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('   ')
    assert_equal 0, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('Invalid')
    assert_equal 0, Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_to_marine_type('Freshwater')
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

  test 'realm_is_marine returns false for invalid values' do
    refute Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine(nil)
    refute Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('')
    refute Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('   ')
    refute Wdpa::Portal::Utils::ProtectedAreaColumnMapper.realm_is_marine('Invalid')
  end

  test 'map_portal_to_pp processes realm field correctly' do
    portal_attributes = {
      'realm' => 'Marine',
      'name' => 'Test PA',
      'site_id' => 123
    }

    dummy_relation = Class.new do
      def initialize(attrs)
        @attrs = attrs
      end

      def create_models
        @attrs
      end
    end

    result = Wdpa::Portal::Utils::ProtectedAreaColumnMapper.map_portal_to_pp_with_relation(
      portal_attributes,
      dummy_relation
    )

    # Should have realm, marine, and marine_type fields (string keys in mapper output)
    assert_equal 'Marine', result['realm']
    assert_equal true, result['marine']
    assert_equal 2, result['marine_type']
    assert_equal 'Test PA', result['original_name']
    assert_equal 123, result['site_id']
  end

  test 'map_portal_to_pp handles empty realm field' do
    portal_attributes = {
      'realm' => '',
      'name' => 'Test PA',
      'site_id' => 123
    }

    dummy_relation = Class.new do
      def initialize(attrs)
        @attrs = attrs
      end

      def create_models
        @attrs
      end
    end

    result = Wdpa::Portal::Utils::ProtectedAreaColumnMapper.map_portal_to_pp_with_relation(
      portal_attributes,
      dummy_relation
    )

    # Blank realm should default to terrestrial / non-marine
    assert_equal '', result['realm']
    assert_equal false, result['marine']
    assert_equal 0, result['marine_type']
  end

  test 'map_portal_to_pp handles invalid realm field' do
    portal_attributes = {
      'realm' => 'Freshwater',
      'name' => 'Test PA',
      'site_id' => 123
    }

    dummy_relation = Class.new do
      def initialize(attrs)
        @attrs = attrs
      end

      def create_models
        @attrs
      end
    end

    result = Wdpa::Portal::Utils::ProtectedAreaColumnMapper.map_portal_to_pp_with_relation(
      portal_attributes,
      dummy_relation
    )

    # Unknown realm should default to terrestrial / non-marine
    assert_equal 'Freshwater', result['realm']
    assert_equal false, result['marine']
    assert_equal 0, result['marine_type']
  end

  test 'map_portal_to_pp processes other fields normally' do
    portal_attributes = {
      'name' => 'Test PA',
      'site_id' => 123,
      'status' => 'Designated'
    }

    dummy_relation = Class.new do
      def initialize(attrs)
        @attrs = attrs
      end

      def create_models
        @attrs
      end
    end

    result = Wdpa::Portal::Utils::ProtectedAreaColumnMapper.map_portal_to_pp_with_relation(
      portal_attributes,
      dummy_relation
    )

    assert_equal 'Test PA', result['original_name']
    assert_equal 123, result['site_id']
    assert_equal 'Designated', result['legal_status']
  end
end
