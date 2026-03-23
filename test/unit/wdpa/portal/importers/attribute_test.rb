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
    notifier.expects(:progress).with(0, 2, 'protected area attributes')
    notifier.expects(:progress).with(2, 2, 'protected area attributes')
    notifier.expects(:phase).with(regexp_matches(/Protected area attributes imported/))

    Rails.logger.stubs(:info)
    Rails.logger.stubs(:error)

    result = @importer.import_to_staging(notifier: notifier)

    assert_equal true, result[:success]
    assert_equal 2, result[:imported_count]
    assert_equal 1, result[:protected_areas_imported_count]
    assert_equal 1, result[:protected_area_parcels_imported_count]
    assert_equal ['soft1'], result[:soft_errors]
    assert_equal [], result[:hard_errors]
  end
end

