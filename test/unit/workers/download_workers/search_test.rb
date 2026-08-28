require 'test_helper'

class DownloadWorkersSearchTest < ActiveSupport::TestCase
  # Helper to access the protected build_site_selection method
  def build_selection(filters)
    worker = DownloadWorkers::Search.new
    worker.send(:build_site_selection, 'search', filters)
  end

  # ---------------------------------------------------------------------------
  # build_search_selection — SQL-mappable filters
  # ---------------------------------------------------------------------------

  test 'build_site_selection search with no filters returns empty flat hash' do
    result = build_selection({})
    assert_equal({}, result)
  end

  test 'build_site_selection search with country filter populates iso3' do
    countries_scope = stub
    Country.stubs(:where).with(name: ['Croatia']).returns(countries_scope)
    countries_scope.stubs(:pluck).with(:iso_3).returns(['HRV'])

    result = build_selection({ 'country' => ['Croatia'] })
    assert_equal ['HRV'], result[:iso3]
  end

  test 'build_site_selection search deduplicates countries when names repeat' do
    countries_scope = stub
    Country.stubs(:where).with(name: ['Croatia', 'Croatia']).returns(countries_scope)
    countries_scope.stubs(:pluck).with(:iso_3).returns(['HRV', 'HRV'])

    result = build_selection({ 'country' => ['Croatia', 'Croatia'] })
    assert_equal ['HRV'], result[:iso3]
  end

  test 'build_site_selection search with region filter expands to iso3 via Region model' do
    region = stub(countries: stub(pluck: %w[GBR IRL]))
    Region.stubs(:where).with(name: ['europe']).returns([region])
    Region.stubs(:where).with(iso: []).returns([])

    result = build_selection({ 'region' => ['europe'] })
    assert_equal %w[GBR IRL], result[:iso3]
  end

  test 'build_site_selection search combines country and region iso3 values' do
    countries_scope = stub
    Country.stubs(:where).with(name: ['France']).returns(countries_scope)
    countries_scope.stubs(:pluck).with(:iso_3).returns(['FRA'])
    region = stub(countries: stub(pluck: ['DEU']))
    Region.stubs(:where).with(name: ['Europe']).returns([region])

    result = build_selection({ 'country' => ['France'], 'region' => ['Europe'] })
    assert_includes result[:iso3], 'FRA'
    assert_includes result[:iso3], 'DEU'
  end

  test 'build_site_selection search resolves region names from UI' do
    region = stub(countries: stub(pluck: ['NGA']))
    Region.stubs(:where).with(name: ['Africa']).returns([region])

    result = build_selection({ 'region' => ['Africa'] })
    assert_equal ['NGA'], result[:iso3]
  end

  test 'build_site_selection search with marine: true sets marine key' do
    result = build_selection({ 'marine' => true })
    assert_equal true, result[:is_marine]
  end

  test 'build_site_selection search with marine: false sets marine key' do
    result = build_selection({ 'marine' => false })
    assert_equal false, result[:is_marine]
  end

  test 'build_site_selection search with is_oecm: true sets is_oecm key' do
    result = build_selection({ 'is_oecm' => true })
    assert_equal true, result[:is_oecm]
  end

  test 'build_site_selection search with iucn_category populates iucn_categories' do
    result = build_selection({ 'iucn_category' => %w[Ia II] })
    assert_equal %w[Ia II], result[:iucn_categories]
  end

  test 'build_site_selection search with designation populates designations' do
    result = build_selection({ 'designation' => ['National Park'] })
    assert_equal ['National Park'], result[:designations]
  end

  test 'build_site_selection search with governance populates governance_types' do
    result = build_selection({ 'governance' => ['Government'] })
    assert_equal ['Government'], result[:governance_types]
  end

  # ---------------------------------------------------------------------------
  # resolve_db_filters — special_status
  # ---------------------------------------------------------------------------

  test 'build_site_selection search with greenlisted special_status returns site_id_and_pid_pairs' do
    ProtectedArea.stubs(:pas_with_green_list_on_self_only).returns(stub(pluck: [[1, '1'], [2, '2']]))
    ProtectedAreaParcel.stubs(:greenlisted_parcels).returns(stub(pluck: [[3, '3']]))

    result = build_selection({ 'special_status' => ['pa_or_any_its_parcels_is_greenlisted'] })
    pairs = result[:site_id_and_pid_pairs]

    assert_includes pairs, [1, '1']
    assert_includes pairs, [2, '2']
    assert_includes pairs, [3, '3']
    assert_nil result[:site_ids]
  end

  test 'build_site_selection search deduplicates greenlist pairs using union' do
    shared_pair = [1, '1']
    ProtectedArea.stubs(:pas_with_green_list_on_self_only).returns(stub(pluck: [shared_pair]))
    ProtectedAreaParcel.stubs(:greenlisted_parcels).returns(stub(pluck: [shared_pair]))

    result = build_selection({ 'special_status' => ['pa_or_any_its_parcels_is_greenlisted'] })
    count = result[:site_id_and_pid_pairs].count { |p| p == shared_pair }
    assert_equal 1, count
  end

  test 'build_site_selection search with has_parcc_info special_status returns site_ids' do
    ProtectedArea.stubs(:where).with(has_parcc_info: true).returns(stub(pluck: [10, 20]))

    result = build_selection({ 'special_status' => ['has_parcc_info'] })
    assert_equal [10, 20], result[:site_ids]
    assert_nil result[:site_id_and_pid_pairs]
  end

  test 'build_site_selection search with is_transboundary special_status returns site_ids' do
    ProtectedArea.stubs(:transboundary_sites).returns(stub(pluck: [5, 6]))

    result = build_selection({ 'special_status' => ['is_transboundary'] })
    assert_equal [5, 6], result[:site_ids]
  end

  test 'build_site_selection search with has_irreplaceability_info returns site_ids' do
    ProtectedArea.stubs(:where).with(has_irreplaceability_info: true).returns(stub(pluck: [7, 8]))

    result = build_selection({ 'has_irreplaceability_info' => true })
    assert_equal [7, 8], result[:site_ids]
  end

  test 'build_site_selection search mixed special_status produces both pairs and site_ids' do
    ProtectedArea.stubs(:pas_with_green_list_on_self_only).returns(stub(pluck: [[1, '1']]))
    ProtectedAreaParcel.stubs(:greenlisted_parcels).returns(stub(pluck: []))
    ProtectedArea.stubs(:where).with(has_parcc_info: true).returns(stub(pluck: [99]))

    result = build_selection({
      'special_status' => %w[pa_or_any_its_parcels_is_greenlisted has_parcc_info]
    })
    assert_equal [[1, '1']], result[:site_id_and_pid_pairs]
    assert_equal [99], result[:site_ids]
  end

  test 'build_site_selection search with requested filters but no matches returns explicit empty selector' do
    ProtectedArea.stubs(:pas_with_green_list_on_self_only).returns(stub(pluck: []))
    ProtectedAreaParcel.stubs(:greenlisted_parcels).returns(stub(pluck: []))

    result = build_selection({ 'special_status' => ['pa_or_any_its_parcels_is_greenlisted'] })
    assert_equal true, result[:has_filters_but_empty_matches]
    assert_nil result[:site_id_and_pid_pairs]
  end

  # ---------------------------------------------------------------------------
  # generate_download
  # ---------------------------------------------------------------------------

  test 'generate_download calls Download.generate with flat selection' do
    worker = DownloadWorkers::Search.new
    worker.instance_variable_set(:@format, 'csv')
    worker.instance_variable_set(:@token, 'abc123')
    worker.instance_variable_set(:@search_term, '')
    worker.instance_variable_set(:@filters_json, '{}')
    worker.instance_variable_set(:@filters_values, [])

    expected_selection = {}
    Download.expects(:generate).with('csv', anything, { site_selection: expected_selection }).returns(true)

    worker.send(:generate_download)
  end

  test 'generate_download raises if Download.generate returns false' do
    worker = DownloadWorkers::Search.new
    worker.instance_variable_set(:@format, 'csv')
    worker.instance_variable_set(:@token, 'abc')
    worker.instance_variable_set(:@search_term, '')
    worker.instance_variable_set(:@filters_json, '{}')
    worker.instance_variable_set(:@filters_values, [])

    Download.stubs(:generate).returns(false)

    assert_raises(RuntimeError) { worker.send(:generate_download) }
  end
end
