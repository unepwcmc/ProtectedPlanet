require 'test_helper'

class Wdpa::Portal::Config::PortalImportConfigTest < ActiveSupport::TestCase
  def setup
    @config = Wdpa::Portal::Config::PortalImportConfig
  end

  test 'constants are defined correctly' do
    assert_equal 'staging_', Wdpa::Portal::Config::PortalImportConfig::STAGING_PREFIX
    assert_equal 'bk', Wdpa::Portal::Config::PortalImportConfig::BACKUP_PREFIX
  end

  test 'portal_views contains all required views' do
    expected_views = {
      'iso3_agg' => 'portal_iso3_agg',
      'parent_iso3_agg' => 'portal_parent_iso3_agg',
      'int_crit_agg' => 'portal_int_crit_agg',
      'polygons' => 'portal_standard_polygons',
      'points' => 'portal_standard_points',
      'sources' => 'portal_standard_sources'
    }

    assert_equal expected_views, @config::PORTAL_VIEWS
  end

  test 'portal_protected_area_view_types contains correct types' do
    expected_types = %w[polygons points]
    assert_equal expected_types, @config::PORTAL_PROTECTED_AREA_VIEW_TYPES
  end

  test 'batch_import_protected_areas_from_view_size returns correct value' do
    assert_equal 10, @config.batch_import_protected_areas_from_view_size
  end

  test 'lock_timeout_ms returns correct value' do
    assert_equal 30_000, @config.lock_timeout_ms
  end

  test 'statement_timeout_ms returns correct value' do
    assert_equal 300_000, @config.statement_timeout_ms
  end

  test 'keep_backup_count returns correct value' do
    assert_equal 2, @config.keep_backup_count
  end

  test 'independent_table_names returns correct mapping' do
    result = @config.independent_table_names

    # Check that it contains expected independent tables
    assert_includes result.keys, 'sources'
    assert_includes result.keys, 'green_list_statuses'
    assert_includes result.keys, 'no_take_statuses'
    assert_includes result.keys, 'country_statistics'
    assert_includes result.keys, 'global_statistics'
    assert_includes result.keys, 'pame_evaluations'
    assert_includes result.keys, 'pame_sources'
    assert_includes result.keys, 'pame_statistics'
    assert_includes result.keys, 'story_map_links'

    # Check that values are staging table names
    assert_includes result.values, 'sources_staging'
    assert_includes result.values, 'green_list_statuses_staging'
  end

  test 'main_entity_tables returns correct mapping' do
    result = @config.main_entity_tables

    # Check that it contains expected main entity tables
    assert_includes result.keys, 'protected_areas'
    assert_includes result.keys, 'protected_area_parcels'

    # Check that values are staging table names
    assert_includes result.values, 'protected_areas_staging'
    assert_includes result.values, 'protected_area_parcels_staging'
  end

  test 'junction_tables returns correct mapping' do
    result = @config.junction_tables

    # Check that it contains expected junction tables
    assert_includes result.keys, 'countries_protected_areas'
    assert_includes result.keys, 'countries_protected_area_parcels'
    assert_includes result.keys, 'countries_pame_evaluations'
    assert_includes result.keys, 'protected_areas_sources'
    assert_includes result.keys, 'protected_area_parcels_sources'

    # Check that values are staging table names
    assert_includes result.values, 'countries_protected_areas_staging'
    assert_includes result.values, 'countries_protected_area_parcels_staging'
  end

  test 'generate_staging_table_index_name adds staging prefix' do
    result = @config.generate_staging_table_index_name('sources_pkey')
    assert_equal 'staging_sources_pkey', result
  end

  test 'generate_live_table_index_name_from_staging removes staging prefix' do
    result = @config.generate_live_table_index_name_from_staging('staging_sources_pkey')
    assert_equal 'sources_pkey', result
  end

  test 'generate_live_table_index_name_from_staging handles multiple prefixes' do
    result = @config.generate_live_table_index_name_from_staging('staging_staging_sources_pkey')
    assert_equal 'staging_sources_pkey', result
  end

  test 'generate_backup_name creates correct backup name' do
    result = @config.generate_backup_name('sources', '2501011200')
    assert_equal 'bk2501011200_sources', result
  end

  test 'is_backup_table? returns true for valid backup table names' do
    assert @config.is_backup_table?('bk2501011200_sources')
    assert @config.is_backup_table?('bk2501011200_protected_areas')
    assert @config.is_backup_table?('bk1234567890_test_table')
  end

  test 'is_backup_table? returns false for invalid backup table names' do
    refute @config.is_backup_table?('sources')
    refute @config.is_backup_table?('bk250101120_sources') # Too short timestamp
    refute @config.is_backup_table?('bk25010112000_sources') # Too long timestamp
    refute @config.is_backup_table?('backup2501011200_sources') # Wrong prefix
    refute @config.is_backup_table?('bk2501011200') # No table name
  end

  test 'extract_backup_timestamp extracts timestamp from backup table name' do
    result = @config.extract_backup_timestamp('bk2501011200_sources')
    assert_equal '2501011200', result
  end

  test 'extract_backup_timestamp handles different table names' do
    result = @config.extract_backup_timestamp('bk2501011200_protected_areas')
    assert_equal '2501011200', result
  end

  test 'extract_table_name_from_backup extracts table name from backup table name' do
    result = @config.extract_table_name_from_backup('bk2501011200_sources')
    assert_equal 'sources', result
  end

  test 'extract_table_name_from_backup handles different table names' do
    result = @config.extract_table_name_from_backup('bk2501011200_protected_areas')
    assert_equal 'protected_areas', result
  end

  test 'remove_backup_suffix removes backup prefix and timestamp' do
    result = @config.remove_backup_suffix('bk2501011200_sources')
    assert_equal 'sources', result
  end

  test 'remove_backup_suffix handles names without backup suffix' do
    result = @config.remove_backup_suffix('sources')
    assert_equal 'sources', result
  end

  test 'staging_live_tables_hash combines all table mappings' do
    result = @config.staging_live_tables_hash

    # Should contain all independent, main entity, and junction tables
    assert_includes result.keys, 'sources'
    assert_includes result.keys, 'protected_areas'
    assert_includes result.keys, 'countries_protected_areas'

    # Should contain corresponding staging table names
    assert_includes result.values, 'sources_staging'
    assert_includes result.values, 'protected_areas_staging'
    assert_includes result.values, 'countries_protected_areas_staging'
  end

  test 'staging_tables returns all staging table names' do
    result = @config.staging_tables

    # Should contain all staging table names
    assert_includes result, 'sources_staging'
    assert_includes result, 'protected_areas_staging'
    assert_includes result, 'countries_protected_areas_staging'
  end

  test 'get_live_table_name_from_staging_name returns correct live table name' do
    result = @config.get_live_table_name_from_staging_name('sources_staging')
    assert_equal 'sources', result
  end

  test 'get_live_table_name_from_staging_name returns nil for unknown staging table' do
    result = @config.get_live_table_name_from_staging_name('unknown_staging')
    assert_nil result
  end

  test 'get_staging_table_name_from_live_table returns correct staging table name' do
    result = @config.get_staging_table_name_from_live_table('sources')
    assert_equal 'sources_staging', result
  end

  test 'get_staging_table_name_from_live_table returns nil for unknown live table' do
    result = @config.get_staging_table_name_from_live_table('unknown_table')
    assert_nil result
  end

  test 'portal_view_for returns correct view name' do
    assert_equal 'portal_standard_polygons', @config.portal_view_for('polygons')
    assert_equal 'portal_standard_points', @config.portal_view_for('points')
    assert_equal 'portal_standard_sources', @config.portal_view_for('sources')
  end

  test 'portal_view_for returns nil for unknown view type' do
    result = @config.portal_view_for('unknown')
    assert_nil result
  end

  test 'portal_views returns all view names' do
    result = @config.portal_views

    expected = %w[
      portal_iso3_agg
      portal_parent_iso3_agg
      portal_int_crit_agg
      portal_standard_polygons
      portal_standard_points
      portal_standard_sources
    ]

    assert_equal expected, result
  end

  test 'portal_protected_area_views returns protected area view names' do
    result = @config.portal_protected_area_views

    expected = %w[portal_standard_polygons portal_standard_points]
    assert_equal expected, result
  end

  test 'swap_sequence_live_table_names returns tables in correct order' do
    result = @config.swap_sequence_live_table_names

    # Should start with independent tables
    independent_tables = @config.independent_table_names.keys
    main_entity_tables = @config.main_entity_tables.keys
    junction_tables = @config.junction_tables.keys

    # Check that independent tables come first
    independent_tables.each do |table|
      assert_includes result, table
      assert result.index(table) < result.index(main_entity_tables.first)
    end

    # Check that main entity tables come before junction tables
    main_entity_tables.each do |table|
      assert_includes result, table
      assert result.index(table) < result.index(junction_tables.first)
    end

    # Check that junction tables come last
    junction_tables.each do |table|
      assert_includes result, table
    end
  end

  test 'swap_sequence_live_table_names is cached' do
    result1 = @config.swap_sequence_live_table_names
    result2 = @config.swap_sequence_live_table_names

    assert_equal result1, result2
    assert_same result1, result2
  end

  test 'all table name methods return consistent results' do
    staging_live_hash = @config.staging_live_tables_hash
    independent_tables = @config.independent_table_names
    main_entity_tables = @config.main_entity_tables
    junction_tables = @config.junction_tables

    # staging_live_tables_hash should contain all tables from the three categories
    all_expected_keys = independent_tables.keys + main_entity_tables.keys + junction_tables.keys
    all_expected_values = independent_tables.values + main_entity_tables.values + junction_tables.values

    all_expected_keys.each do |key|
      assert_includes staging_live_hash.keys, key
    end

    all_expected_values.each do |value|
      assert_includes staging_live_hash.values, value
    end
  end
end
