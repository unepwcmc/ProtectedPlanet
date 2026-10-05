require 'test_helper'

class Wdpa::Portal::Importers::ProtectedAreaAttributeImporterTest < ActiveSupport::TestCase
  def setup
    @importer = Wdpa::Portal::Importers::ProtectedArea::Attribute
  end

  test '.current_entry_parcel_info flags first or only parcel when no multiple-parcel map entry' do
    info = @importer.current_entry_parcel_info(
      { 'site_id' => 1, 'site_pid' => '1' },
      {}
    )

    assert info[:is_first_or_only_parcel]
    refute info[:has_multiple_parcels]
  end

  test '.current_entry_parcel_info distinguishes first parcel from subsequent parcels when map present' do
    map = { 1 => '1_1' }

    first_info = @importer.current_entry_parcel_info(
      { 'site_id' => 1, 'site_pid' => '1_1' },
      map
    )
    assert first_info[:is_first_or_only_parcel]
    assert first_info[:has_multiple_parcels]

    later_info = @importer.current_entry_parcel_info(
      { 'site_id' => 1, 'site_pid' => '1_2' },
      map
    )
    refute later_info[:is_first_or_only_parcel]
    assert later_info[:has_multiple_parcels]
  end

  test '.import_to_staging aggregates batch results and notifies via notifier' do
    # Stub map of site IDs with multiple parcels
    @importer.stubs(:get_site_ids_with_multiple_site_pids_map).returns({})

    # Stub adapter relation to yield a single batch of records
    relation = mock('protected_areas_relation')
    relation.expects(:count).returns(2)
    relation.expects(:find_in_batches).yields(%w[row1 row2])

    adapter = mock('import_views_adapter')
    adapter.expects(:protected_areas_relation).returns(relation)
    Wdpa::Portal::Adapters::ImportViewsAdapter.expects(:new).returns(adapter)

    # Stub per-batch processing so we can focus on aggregation behavior
    @importer.expects(:process_batch).with(%w[row1 row2], {}).returns(
      { count: 2, pa_count: 1, parcel_count: 1, soft_errors: ['soft1'] }
    )

    # Progress interval and notifier expectations
    Wdpa::Portal::Config::PortalImportConfig.stubs(:progress_notification_interval).returns(2)

    notifier = mock('notifier')
    notifier.expects(:progress).with(0, 2, 'portal WDPCA rows')
    notifier.expects(:progress).with(2, 2, 'portal WDPCA rows')
    notifier.expects(:phase).with(regexp_matches(/Protected areas: \d+ rows/))

    Rails.logger.stubs(:info)
    Rails.logger.stubs(:warn)
    Rails.logger.stubs(:error)

    result = @importer.import_to_staging(notifier: notifier)

    assert_equal true, result[:success]
    assert_equal 2, result[:imported_count]
    assert_equal 1, result[:protected_areas_imported_count]
    assert_equal 1, result[:protected_area_parcels_imported_count]
    assert_equal ['soft1'], result[:soft_errors]
    assert_equal [], result[:hard_errors]
  end

  # --- Total-failure reporting -------------------------------------------------
  #
  # When every row of a non-empty source fails, the import used to report
  # success: true, imported_count: 0, leaving the causes in soft_errors. The
  # release then failed at geometry with a message naming the symptom, not the
  # cause. These pin the escalation AND its narrowness: a partial drop must stay
  # soft, or a release that works on real data today would start failing.

  def run_import_with(total:, batch_result:)
    @importer.stubs(:get_site_ids_with_multiple_site_pids_map).returns({})
    relation = mock('protected_areas_relation')
    relation.stubs(:count).returns(total)
    relation.stubs(:find_in_batches).yields(%w[row])
    adapter = mock('import_views_adapter')
    adapter.stubs(:protected_areas_relation).returns(relation)
    Wdpa::Portal::Adapters::ImportViewsAdapter.stubs(:new).returns(adapter)
    @importer.stubs(:process_batch).returns(batch_result)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:progress_notification_interval).returns(1_000)
    Rails.logger.stubs(:info)
    Rails.logger.stubs(:warn)
    @importer.import_to_staging
  end

  test 'every row failing is a hard error that carries the real cause' do
    cause = "Row error processing SITE_ID 900001 SITE_PID 900001: undefined method 'match' for nil"
    result = run_import_with(total: 1, batch_result: { count: 0, pa_count: 0, parcel_count: 0, soft_errors: [cause] })

    refute result[:success]
    assert_equal 1, result[:hard_errors].size
    assert_match(/All 1 portal WDPCA rows failed to import/, result[:hard_errors].first)
    assert_includes result[:hard_errors].first, cause,
                    'the underlying row error must reach the hard error, not stay buried in soft_errors'
  end

  test 'the hard error samples a few causes rather than dumping every row' do
    causes = (1..10).map { |i| "Row error processing SITE_ID #{i}" }
    result = run_import_with(total: 10, batch_result: { count: 0, pa_count: 0, parcel_count: 0, soft_errors: causes })

    message = result[:hard_errors].first
    assert_includes message, 'SITE_ID 1'
    assert_includes message, 'SITE_ID 3'
    refute_includes message, 'SITE_ID 4', 'only the first few causes, so a 320k-row failure stays readable'
  end

  # The guard that matters for real releases: real portal data can have a few bad
  # rows, and that must keep succeeding exactly as it did before.
  test 'a partial drop stays a soft error and the import still succeeds' do
    result = run_import_with(total: 3, batch_result: { count: 2, pa_count: 2, parcel_count: 0, soft_errors: ['one bad row'] })

    assert result[:success]
    assert_empty result[:hard_errors]
    assert_equal ['one bad row'], result[:soft_errors]
  end

  test 'a fully successful import is unchanged' do
    result = run_import_with(total: 2, batch_result: { count: 2, pa_count: 2, parcel_count: 0, soft_errors: [] })

    assert result[:success]
    assert_empty result[:hard_errors]
  end

  # An empty source is a different failure, already reported at geometry. Leaving
  # it alone keeps this change to the one case it was written for.
  test 'an empty source raises no new hard error here' do
    result = run_import_with(total: 0, batch_result: { count: 0, pa_count: 0, parcel_count: 0, soft_errors: [] })

    assert result[:success]
    assert_empty result[:hard_errors]
  end
end
