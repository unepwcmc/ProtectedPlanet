require 'test_helper'

class Wdpa::Portal::Adapters::SourcesTest < ActiveSupport::TestCase
  def setup
    @adapter = Wdpa::Portal::Adapters::Sources.new
    @connection = ActiveRecord::Base.connection

    # Mock the configuration
    @config = mock('PortalImportConfig')
    @config.stubs(:portal_materialised_view_for).with('sources').returns('portal_standard_sources')

    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_materialised_view_for).with('sources').returns(@config.portal_materialised_view_for('sources'))
  end

  def teardown
    # Clean up any test views
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_sources CASCADE')
  end

  test 'each processes all records when view exists' do
    # Create test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_sources AS
      SELECT 1 as id, 'Source 1' as title, 'Description 1' as description, 2024 as year, 'en' as language
      UNION ALL
      SELECT 2 as id, 'Source 2' as title, 'Description 2' as description, 2023 as year, 'en' as language
      UNION ALL
      SELECT 3 as id, 'Source 3' as title, 'Description 3' as description, 2022 as year, 'fr' as language
    SQL

    records = []
    @adapter.each do |record|
      records << record
    end

    # Should have 3 records
    assert_equal 3, records.length
    assert_equal 'Source 1', records[0]['title']
    assert_equal 'Source 2', records[1]['title']
    assert_equal 'Source 3', records[2]['title']
  end

  test 'each raises error when view does not exist' do
    # Don't create the view

    assert_raises(StandardError, /portal_standard_sources table is required but does not exist/) do
      @adapter.each { |_record| _ = record }
    end
  end

  test 'each handles empty view' do
    # Create empty materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_sources AS
      SELECT 1 as id, 'test' as title, 'test' as description, 2024 as year, 'en' as language
      WHERE 1 = 0
    SQL

    records = []
    @adapter.each do |record|
      records << record
    end

    # Should have no records
    assert_equal 0, records.length
  end

  test 'count returns correct count when view exists' do
    # Create test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_sources AS
      SELECT 1 as id, 'Source 1' as title, 'Description 1' as description, 2024 as year, 'en' as language
      UNION ALL
      SELECT 2 as id, 'Source 2' as title, 'Description 2' as description, 2023 as year, 'en' as language
      UNION ALL
      SELECT 3 as id, 'Source 3' as title, 'Description 3' as description, 2022 as year, 'fr' as language
    SQL

    result = @adapter.count

    assert_equal 3, result
  end

  test 'count raises error when view does not exist' do
    # Don't create the view

    assert_raises(StandardError, /portal_standard_sources table is required but does not exist/) do
      @adapter.count
    end
  end

  test 'count returns zero for empty view' do
    # Create empty materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_sources AS
      SELECT 1 as id, 'test' as title, 'test' as description, 2024 as year, 'en' as language
      WHERE 1 = 0
    SQL

    result = @adapter.count

    assert_equal 0, result
  end

  test 'portal_sources_exist? returns true when view exists' do
    # Create test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_sources AS
      SELECT 1 as id, 'test' as title, 'test' as description, 2024 as year, 'en' as language
    SQL

    result = @adapter.portal_sources_exist?
    assert result
  end

  test 'portal_sources_exist? returns false when view does not exist' do
    # Don't create the view

    result = @adapter.portal_sources_exist?
    refute result
  end

  test 'portal_sources_exist? delegates to ViewManager' do
    Wdpa::Portal::Managers::ViewManager.expects(:view_exists?).with('portal_standard_sources').returns(true)

    result = @adapter.portal_sources_exist?
    assert result
  end

  test 'each handles database errors gracefully' do
    # Create test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_sources AS
      SELECT 1 as id, 'test' as title, 'test' as description, 2024 as year, 'en' as language
    SQL

    # Mock the connection to raise an error
    @connection.expects(:select_all).raises(StandardError, 'Database error')

    assert_raises(StandardError, 'Database error') do
      @adapter.each { |_record| _ = record }
    end
  end

  test 'count handles database errors gracefully' do
    # Create test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_sources AS
      SELECT 1 as id, 'test' as title, 'test' as description, 2024 as year, 'en' as language
    SQL

    # Mock the connection to raise an error
    @connection.expects(:select_value).raises(StandardError, 'Database error')

    assert_raises(StandardError, 'Database error') do
      @adapter.count
    end
  end

  test 'each with block that modifies records' do
    # Create test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_sources AS
      SELECT 1 as id, 'Source 1' as title, 'Description 1' as description, 2024 as year, 'en' as language
      UNION ALL
      SELECT 2 as id, 'Source 2' as title, 'Description 2' as description, 2023 as year, 'en' as language
    SQL

    modified_records = []
    @adapter.each do |record|
      record['modified'] = true
      modified_records << record
    end

    # Should have 2 records with modified flag
    assert_equal 2, modified_records.length
    assert modified_records[0]['modified']
    assert modified_records[1]['modified']
  end

  test 'each without block returns enumerator' do
    # Create test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_sources AS
      SELECT 1 as id, 'Source 1' as title, 'Description 1' as description, 2024 as year, 'en' as language
    SQL

    enumerator = @adapter.each

    assert_instance_of Enumerator, enumerator
    assert_equal 1, enumerator.to_a.length
  end
end
