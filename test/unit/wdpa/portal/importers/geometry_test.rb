require 'test_helper'

# Characterization tests for the WDPA portal geometry importer, which was 0% covered.
# It runs raw PostGIS SQL against staging tables + materialized views that don't exist
# in the test DB, so (matching the sibling importer tests) we mock the connection layer
# and assert the branching logic, SQL shape, result aggregation, and error handling --
# the parts an upgrade (Rails / PG / PostGIS / adapter) is most likely to break.
class Wdpa::Portal::Importers::GeometryTest < ActiveSupport::TestCase
  Importer = Wdpa::Portal::Importers::ProtectedArea::Geometry
  PA_TABLE      = Staging::ProtectedArea.table_name        # staging_protected_areas
  PARCEL_TABLE  = Staging::ProtectedAreaParcel.table_name  # staging_protected_area_parcels

  def setup
    @conn = mock('connection')
    ActiveRecord::Base.stubs(:lease_connection).returns(@conn)
    Rails.logger.stubs(:info); Rails.logger.stubs(:warn)
    Rails.logger.stubs(:error); Rails.logger.stubs(:debug)
  end

  # --- pure mapping logic (no DB) ---
  test '.find_geometry_columns_from_mapping pulls geometry-typed columns from the mapping' do
    cols = Importer.find_geometry_columns_from_mapping
    assert_includes cols, 'the_geom', 'the_geom is the mapped PostGIS column'
    assert cols.all? { |c| c.is_a?(String) }
  end

  # --- get_matching_condition: site_pid drives the join ---
  test '.get_matching_condition matches on site_id + site_pid when the table has site_pid (parcels)' do
    @conn.stubs(:column_exists?).with(PARCEL_TABLE, 'site_pid').returns(true)
    sql = Importer.get_matching_condition(PARCEL_TABLE)
    assert_match(/site_id = v\.site_id/, sql)
    assert_match(/site_pid::text = v\.site_pid::text/, sql)
  end

  test '.get_matching_condition matches on site_id only when there is no site_pid (protected areas)' do
    @conn.stubs(:column_exists?).with(PA_TABLE, 'site_pid').returns(false)
    sql = Importer.get_matching_condition(PA_TABLE)
    assert_match(/site_id = v\.site_id/, sql)
    refute_match(/site_pid/, sql)
  end

  # --- get_geometry_column: first mapped geometry column present on the table ---
  test '.get_geometry_column returns the first mapped geometry column that exists on the table' do
    @conn.stubs(:column_exists?).returns(false)
    @conn.stubs(:column_exists?).with(PA_TABLE, 'the_geom').returns(true)
    assert_equal 'the_geom', Importer.get_geometry_column(PA_TABLE)
  end

  test '.get_geometry_column returns nil when no mapped geometry column exists' do
    @conn.stubs(:column_exists?).returns(false)
    assert_nil Importer.get_geometry_column(PA_TABLE)
  end

  # --- validate_target_table ---
  test '.validate_target_table is false when the table does not exist' do
    @conn.stubs(:table_exists?).with(PA_TABLE).returns(false)
    refute Importer.validate_target_table(PA_TABLE)
  end

  test '.validate_target_table is a hard failure when the protected-area table is empty' do
    @conn.stubs(:table_exists?).with(PA_TABLE).returns(true)
    @conn.stubs(:execute).returns([{ 'count' => '0' }])
    refute Importer.validate_target_table(PA_TABLE)
  end

  test '.validate_target_table tolerates an empty parcels table (warn, continue)' do
    @conn.stubs(:table_exists?).with(PARCEL_TABLE).returns(true)
    @conn.stubs(:execute).returns([{ 'count' => '0' }])
    assert Importer.validate_target_table(PARCEL_TABLE)
  end

  test '.validate_target_table is true for a populated table' do
    @conn.stubs(:table_exists?).with(PA_TABLE).returns(true)
    @conn.stubs(:execute).returns([{ 'count' => '42' }])
    assert Importer.validate_target_table(PA_TABLE)
  end

  # --- import_geometry_from_view: SQL shape + coordinate follow-up ---
  test '.import_geometry_from_view fails when the table has no geometry column' do
    Importer.stubs(:get_geometry_column).returns(nil)
    result = Importer.import_geometry_from_view('v_view', PA_TABLE)
    refute result[:success]
    assert_equal 0, result[:imported_count]
  end

  test '.import_geometry_from_view runs the UPDATE, counts cmd_tuples, and computes coordinates when rows changed' do
    Importer.stubs(:get_geometry_column).with(PA_TABLE).returns('the_geom')
    Importer.stubs(:get_matching_condition).with(PA_TABLE).returns("#{PA_TABLE}.site_id = v.site_id")
    @conn.stubs(:transaction).yields
    exec_result = mock('pg_result'); exec_result.stubs(:cmd_tuples).returns(5)
    @conn.expects(:execute).with(regexp_matches(/UPDATE #{PA_TABLE}.*SET the_geom = v\.wkb_geometry.*FROM v_view/m)).returns(exec_result)
    # coordinates computed because imported_count > 0
    Importer.expects(:import_coordinates).with('the_geom', PA_TABLE)

    result = Importer.import_geometry_from_view('v_view', PA_TABLE)
    assert result[:success]
    assert_equal 5, result[:imported_count]
    assert_equal 5, result[:number_of_records_updated]
  end

  test '.import_geometry_from_view skips coordinate calculation when no rows changed' do
    Importer.stubs(:get_geometry_column).returns('the_geom')
    Importer.stubs(:get_matching_condition).returns('cond')
    @conn.stubs(:transaction).yields
    exec_result = mock('pg_result'); exec_result.stubs(:cmd_tuples).returns(0)
    @conn.stubs(:execute).returns(exec_result)
    Importer.expects(:import_coordinates).never

    result = Importer.import_geometry_from_view('v_view', PA_TABLE)
    assert_equal 0, result[:imported_count]
  end

  # --- import_coordinates: guarded on lon/lat columns; PostGIS centroid SQL ---
  test '.import_coordinates skips when the coordinate columns are absent' do
    @conn.stubs(:column_exists?).returns(false)
    @conn.expects(:execute).never
    Importer.import_coordinates('the_geom', PA_TABLE)
  end

  test '.import_coordinates runs a ST_Centroid update when the coordinate columns exist' do
    @conn.stubs(:column_exists?).with(PA_TABLE, 'the_geom_longitude').returns(true)
    @conn.stubs(:column_exists?).with(PA_TABLE, 'the_geom_latitude').returns(true)
    @conn.stubs(:transaction).yields
    exec_result = mock('pg_result'); exec_result.stubs(:cmd_tuples).returns(3)
    @conn.expects(:execute).with(regexp_matches(/ST_Centroid\(the_geom\).*ST_MakeValid\(the_geom\)/m)).returns(exec_result)
    Importer.import_coordinates('the_geom', PA_TABLE)
  end

  # --- import_geometry_for_table: aggregation, checkpoint skip, error isolation ---
  test '.import_geometry_for_table returns a failure result when validation fails' do
    Importer.stubs(:validate_target_table).with(PA_TABLE).returns(false)
    result = Importer.import_geometry_for_table(PA_TABLE)
    refute result[:success]
    assert_equal 0, result[:imported_count]
  end

  test '.import_geometry_for_table aggregates imported counts across views' do
    Importer.stubs(:validate_target_table).returns(true)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_protected_area_staging_materialised_views)
      .returns(%w[v_one v_two])
    Wdpa::Portal::ImportRuntimeConfig.stubs(:checkpoints?).returns(false)
    Importer.stubs(:import_geometry_from_view).returns(
      { imported_count: 4, soft_errors: [], hard_errors: [] }
    )
    result = Importer.import_geometry_for_table(PA_TABLE)
    assert_equal 8, result[:imported_count] # 4 per view * 2 views
    assert result[:success]
  end

  test '.import_geometry_for_table isolates a failing view into hard_errors and keeps going' do
    Importer.stubs(:validate_target_table).returns(true)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_protected_area_staging_materialised_views)
      .returns(%w[v_bad v_ok])
    Wdpa::Portal::ImportRuntimeConfig.stubs(:checkpoints?).returns(false)
    Importer.stubs(:import_geometry_from_view).with('v_bad', PA_TABLE).raises(StandardError, 'boom')
    Importer.stubs(:import_geometry_from_view).with('v_ok', PA_TABLE).returns(
      { imported_count: 2, soft_errors: [], hard_errors: [] }
    )
    result = Importer.import_geometry_for_table(PA_TABLE)
    assert_equal 2, result[:imported_count]
    refute result[:success]
    assert(result[:hard_errors].any? { |e| e.include?('boom') })
  end

  test '.import_geometry_for_table honours checkpoints by skipping completed views' do
    Importer.stubs(:validate_target_table).returns(true)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_protected_area_staging_materialised_views)
      .returns(%w[v_done])
    Wdpa::Portal::ImportRuntimeConfig.stubs(:checkpoints?).returns(true)
    Wdpa::Portal::Checkpoint.stubs(:geometry_done?).with('v_done', PA_TABLE).returns(true)
    Importer.expects(:import_geometry_from_view).never

    result = Importer.import_geometry_for_table(PA_TABLE)
    assert_equal 0, result[:imported_count]
  end

  # --- import_to_staging: combines both tables + notifies ---
  test '.import_to_staging imports both tables and reports counts via the notifier' do
    Importer.stubs(:import_geometry_for_table).with(PA_TABLE).returns(
      { imported_count: 10, success: true, soft_errors: [], hard_errors: [] }
    )
    Importer.stubs(:import_geometry_for_table).with(PARCEL_TABLE).returns(
      { imported_count: 3, success: true, soft_errors: [], hard_errors: [] }
    )
    notifier = mock('notifier')
    notifier.expects(:phase).with(regexp_matches(/10 PA Geometries imported, 3 PA parcel geometries imported/))

    result = Importer.import_to_staging(notifier: notifier)
    assert_equal 10, result[:protected_areas][:imported_count]
    assert_equal 3, result[:protected_area_parcels][:imported_count]
  end
end
