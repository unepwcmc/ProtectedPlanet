require 'test_helper'

class Wdpa::Portal::Importers::StatsDbSourceTest < ActiveSupport::TestCase
  def setup
    Wdpa::Portal::ImportRuntimeConfig.reset!
    Wdpa::Portal::ImportRuntimeConfig.label = 'Jun2026'
  end

  def teardown
    Wdpa::Portal::ImportRuntimeConfig.reset!
  end

  test 'select_run_id raises MissingStatsError when no rows for vintage' do
    ActiveRecord::Base.connection.stubs(:select_value).returns(nil)

    error = assert_raises(Wdpa::Portal::Importers::StatsDbSource::Base::MissingStatsError) do
      Wdpa::Portal::Importers::StatsDbSource::NationalStats.rows
    end
    assert_match(/vintage Jun2026/, error.message)
    assert_match(/PP_STATS_SOURCE=csv/, error.message)
  end

  test 'vintage raises MissingStatsError when release label not set' do
    Wdpa::Portal::ImportRuntimeConfig.label = nil

    assert_raises(Wdpa::Portal::Importers::StatsDbSource::Base::MissingStatsError) do
      Wdpa::Portal::Importers::StatsDbSource::NationalStats.rows
    end
  end

  test 'national stats maps columns and converts fraction percentages to 0-100' do
    ActiveRecord::Base.connection.stubs(:select_value).returns('_NS_run_1')
    result = stub(to_a: [{
      'iso3' => 'ABW',
      'pa_marine' => 108.69,
      'pa_terrestrial' => 48.35,
      'total_marine' => 29977.66,
      'total_terrestrial' => 179.72,
      'pa_oecm_marine' => 108.69,
      'pa_oecm_terrestrial' => 48.35,
      'pa_marine_pct' => 0.0036256999378870797,
      'pa_terrestrial_pct' => 0.269,
      'pa_oecm_marine_pct' => Float::NAN,
      'pa_oecm_terrestrial_pct' => nil
    }])
    ActiveRecord::Base.connection.stubs(:select_all).returns(result)

    rows = Wdpa::Portal::Importers::StatsDbSource::NationalStats.rows

    assert_equal 1, rows.length
    assert_equal 'ABW', rows.first[:iso3]
    attrs = rows.first[:attrs]
    assert_equal 108.69, attrs['pa_marine_area']
    assert_equal 48.35, attrs['pa_land_area']
    assert_equal 29977.66, attrs['marine_area']
    assert_equal 179.72, attrs['land_area']
    assert_in_delta 26.9, attrs['percentage_pa_land_cover'], 0.0001
    assert_in_delta 0.36257, attrs['percentage_pa_marine_cover'], 0.0001
    assert_nil attrs['percentage_oecms_pa_marine_cover'] # NaN -> nil
    assert_nil attrs['percentage_oecms_pa_land_cover']   # nil -> nil
  end

  test 'pame stats maps pame_ prefixed columns' do
    ActiveRecord::Base.connection.stubs(:select_value).returns('_PAME_run_1')
    result = stub(to_a: [{
      'iso3' => 'AFG',
      'pame_pa_marine' => 0.0,
      'pame_pa_terrestrial' => 606.27,
      'pame_pa_marine_pct' => Float::NAN,
      'pame_pa_terrestrial_pct' => 0.0009446189393456389
    }])
    ActiveRecord::Base.connection.stubs(:select_all).returns(result)

    rows = Wdpa::Portal::Importers::StatsDbSource::PameStats.rows

    attrs = rows.first[:attrs]
    assert_equal 606.27, attrs['pame_pa_land_area']
    assert_equal 0.0, attrs['pame_pa_marine_area']
    assert_in_delta 0.09446, attrs['pame_percentage_pa_land_cover'], 0.0001
    assert_nil attrs['pame_percentage_pa_marine_cover']
  end

  test 'global stats overlay keeps known stat_types without scaling and soft-errors unknown ones' do
    ActiveRecord::Base.connection.stubs(:select_value).returns('_GS_run_1')
    result = stub(to_a: [
      { 'stat_type' => 'global_ocean_percentage', 'stat_value' => '61' },
      { 'stat_type' => 'not_a_real_column', 'stat_value' => '42' },
      { 'stat_type' => '', 'stat_value' => 'ignored' }
    ])
    ActiveRecord::Base.connection.stubs(:select_all).returns(result)
    Staging::GlobalStatistic.stubs(:column_names).returns(%w[id singleton_guard global_ocean_percentage green_list_count])

    soft_errors = []
    attrs = Wdpa::Portal::Importers::StatsDbSource::GlobalStats.overlay_attrs(soft_errors: soft_errors)

    assert_equal 61.0, attrs['global_ocean_percentage'] # no x100
    refute attrs.key?('not_a_real_column')
    refute attrs.key?('green_list_count') # not emitted by stats server -> stays CSV-only
    assert_equal 1, soft_errors.length
    assert_match(/not_a_real_column/, soft_errors.first)
  end

  test 'num and pct helpers handle NaN string and numeric NaN' do
    base = Wdpa::Portal::Importers::StatsDbSource::NationalStats

    assert_nil base.num('NaN')
    assert_nil base.num(Float::NAN)
    assert_nil base.num(nil)
    assert_equal 1.5, base.num(1.5)
    assert_nil base.pct(Float::NAN)
    assert_in_delta 26.9, base.pct(0.269), 0.0001
  end

  test 'stats_source config validates values and defaults to csv' do
    assert_equal 'csv', Wdpa::Portal::ImportRuntimeConfig.stats_source
    refute Wdpa::Portal::ImportRuntimeConfig.stats_from_db?

    Wdpa::Portal::ImportRuntimeConfig.stats_source = 'db'
    assert Wdpa::Portal::ImportRuntimeConfig.stats_from_db?

    Wdpa::Portal::ImportRuntimeConfig.stats_source = ''
    assert_equal 'csv', Wdpa::Portal::ImportRuntimeConfig.stats_source

    assert_raises(ArgumentError) do
      Wdpa::Portal::ImportRuntimeConfig.stats_source = 'bogus'
    end
  end

  test 'import_country_statistics from db imports known countries only, merging NR fields from CSV' do
    Wdpa::Portal::ImportRuntimeConfig.stats_source = 'db'

    Country.stubs(:pluck).returns([[1, 'ABW']])
    Wdpa::Portal::Importers::StatsDbSource::NationalStats.stubs(:rows).returns([
      { iso3: 'ABW', attrs: { 'pa_land_area' => 48.35, 'percentage_pa_land_cover' => 26.9 } },
      { iso3: 'ABNJ', attrs: { 'pa_marine_area' => 3172433.65 } }
    ])
    Wdpa::Portal::Importers::CountryStatistics.stubs(:nr_attrs_by_iso3).returns(
      'ABW' => { 'percentage_nr_land_cover' => nil, 'nr_version' => '6' }
    )

    saved = []
    record = mock('staging_country_statistic')
    record.stubs(:assign_attributes).with { |attrs| saved << attrs; true }
    record.stubs(:save!).returns(true)
    Staging::CountryStatistic.stubs(:find_or_initialize_by).returns(record)

    result = Wdpa::Portal::Importers::CountryStatistics.import_country_statistics

    assert result[:success]

    # The DB path iterates known countries (so every country gets a row, zero-filled
    # when the stats server returned nothing for it). Source rows with no matching
    # Country - e.g. ABNJ / high seas - are therefore not imported. Nothing consumes
    # a nil-country statistic: the high-seas figures shown on the site come from the
    # global stats and the marine growth CSV instead.
    assert_equal 1, result[:imported_count]

    abw = saved.find { |a| a[:country_id] == 1 }
    assert_equal '6', abw['nr_version']
    assert_equal 26.9, abw['percentage_pa_land_cover']
    assert_nil saved.find { |a| a[:country_id].nil? }, 'unmatched iso3 rows are not imported'
  end

  test 'import_country_statistics from db returns hard error when stats missing for vintage' do
    Wdpa::Portal::ImportRuntimeConfig.stats_source = 'db'
    Country.stubs(:pluck).returns([])
    ActiveRecord::Base.connection.stubs(:select_value).returns(nil)

    result = Wdpa::Portal::Importers::CountryStatistics.import_country_statistics

    refute result[:success]
    assert_match(/No rows in stats.national_stats/, result[:hard_errors].first)
  end

  test 'import_pame_statistics from db merges pame_assessments' do
    Wdpa::Portal::ImportRuntimeConfig.stats_source = 'db'

    Country.stubs(:pluck).returns([[7, 'AFG']])
    Wdpa::Portal::Importers::StatsDbSource::PameStats.stubs(:rows).returns([
      { iso3: 'AFG', attrs: { 'pame_pa_land_area' => 606.27 } }
    ])
    Wdpa::Portal::Importers::CountryStatistics.stubs(:pame_assessments).with(7).returns(
      assessments: 3, assessed_pas: 2
    )

    saved = nil
    record = mock('staging_pame_statistic')
    record.stubs(:assign_attributes).with { |attrs| saved = attrs; true }
    record.stubs(:save!).returns(true)
    Staging::PameStatistic.stubs(:find_or_initialize_by).returns(record)

    result = Wdpa::Portal::Importers::CountryStatistics.import_pame_statistics

    assert result[:success]
    assert_equal 3, saved[:assessments]
    assert_equal 606.27, saved['pame_pa_land_area']
  end
end
