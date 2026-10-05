require 'test_helper'

class DownloadGeneratorsBaseTest < ActiveSupport::TestCase
  # Download::Config branches on whether a successful portal release exists:
  # site_id column is SITE_ID (portal) vs WDPAID, plus PORTAL_* vs STANDARD_*
  # column lists. These tests assert the portal form, so pin it here instead of
  # depending on DB state.
  setup do
  end

  test '#generate, given a path and an empty selection, returns immediately' do
    Download::Generators::Base.any_instance.expects(:export).never
    Download::Generators::Base.any_instance.expects(:zip).never

    Download::Generators::Base.generate('./none.zip', { site_ids: [] })
  end

  # ---------------------------------------------------------------------------
  # selection_entries_empty? — unified flat shape
  # ---------------------------------------------------------------------------

  test 'selection_entries_empty? returns false when selection hash is empty' do
    generator = Download::Generators::Base.new('./none.zip', {})
    assert_equal false, generator.send(:selection_entries_empty?)
  end

  test 'selection_entries_empty? returns true when has_filters_but_empty_matches flag is set' do
    generator = Download::Generators::Base.new('./none.zip', { has_filters_but_empty_matches: true })
    assert_equal true, generator.send(:selection_entries_empty?)
  end

  test 'selection_entries_empty? returns false when flat selection hash has values' do
    generator = Download::Generators::Base.new('./none.zip', {
      iso3: ['GBR']
    })
    assert_equal false, generator.send(:selection_entries_empty?)
  end

  # ---------------------------------------------------------------------------
  # Individual search clause builders
  # ---------------------------------------------------------------------------

  def generator
    Download::Generators::Base.new('./none.zip', {})
  end

  test 'build_iso3_clause produces ISO3 IN clause' do
    clause = generator.send(:build_iso3_clause, %w[GBR FRA])
    assert clause.include?('ISO3')
    assert clause.include?('GBR')
  end

  test 'build_marine_clause with true produces REALM IN marine values clause' do
    clause = generator.send(:build_marine_clause, true)
    assert clause.include?('REALM')
    assert clause.include?('Marine')
  end

  test 'build_marine_clause with false produces REALM IN terrestrial values clause' do
    clause = generator.send(:build_marine_clause, false)
    assert clause.include?('REALM')
    assert clause.include?('Terrestrial')
  end

  test 'build_is_oecm_clause with true produces SITE_TYPE IN clause' do
    clause = generator.send(:build_is_oecm_clause, true)
    assert clause.include?('SITE_TYPE')
    assert clause.include?('IN')
    assert_not clause.include?('NOT IN')
  end

  test 'build_is_oecm_clause with false produces SITE_TYPE IN PA clause' do
    clause = generator.send(:build_is_oecm_clause, false)
    assert clause.include?('SITE_TYPE')
    assert clause.include?('IN')
    assert clause.include?('PA')
  end

  test 'build_iucn_categories_clause produces IUCN_CAT IN clause' do
    clause = generator.send(:build_iucn_categories_clause, %w[Ia II])
    assert clause.include?('IUCN_CAT')
    assert clause.include?("'Ia'")
    assert clause.include?("'II'")
  end

  test 'build_iucn_categories_clause returns nil for blank input' do
    assert_nil generator.send(:build_iucn_categories_clause, [])
  end

  test 'build_designations_clause produces DESIG_ENG IN clause' do
    clause = generator.send(:build_designations_clause, ['National Park'])
    assert clause.include?('DESIG_ENG')
    assert clause.include?('National Park')
  end

  test 'build_governance_types_clause produces GOV_TYPE IN clause' do
    clause = generator.send(:build_governance_types_clause, ['Government'])
    assert clause.include?('GOV_TYPE')
    assert clause.include?('Government')
  end

  test 'add_conditions with flat site_ids produces SITE_ID IN clause' do
    gen = Download::Generators::Base.new('./none.zip', { site_ids: [1, 2, 3] })
    result = gen.send(:add_conditions, 'SELECT * FROM v', [])
    assert result.include?('SITE_ID')
    assert result.include?('1')
  end

  test 'add_conditions with flat site_id_and_pid_pairs produces paired clause' do
    gen = Download::Generators::Base.new('./none.zip', { site_id_and_pid_pairs: [[10, '10-1']] })
    result = gen.send(:add_conditions, 'SELECT * FROM v', [])
    assert result.include?('SITE_ID')
    assert result.include?('10-1')
  end

  test 'add_conditions with site_ids and pairs OR-es them as one AND entry' do
    gen = Download::Generators::Base.new('./none.zip', {
      site_ids: [1], site_id_and_pid_pairs: [[2, '2-1']]
    })
    result = gen.send(:add_conditions, 'SELECT * FROM v', [])
    assert result.include?(' OR '), 'Expected site_ids and pairs to be OR-ed together'
    assert result.include?(' AND '), 'Expected the combined clause to be AND-ed with the WHERE'
  end

  test 'add_conditions with empty flat hash adds no WHERE conditions' do
    gen = Download::Generators::Base.new('./none.zip', {})
    result = gen.send(:add_conditions, 'SELECT * FROM v', [])
    assert_not result.include?('WHERE')
  end

  test 'add_conditions with empty flat hash does not add 1=0 guard' do
    gen = Download::Generators::Base.new('./none.zip', {})
    result = gen.send(:add_conditions, 'SELECT * FROM v', [])
    assert_not result.include?('1=0')
  end

  test 'add_conditions ANDs all filter clauses' do
    generator = Download::Generators::Base.new('./none.zip', { iso3: ['GBR'], is_marine: true })
    # Build a minimal query and check that both conditions appear AND-ed
    query = 'SELECT * FROM downloads_view'
    result = generator.send(:add_conditions, query, [])
    assert result.include?('ISO3'), 'Expected ISO3 condition in query'
    assert result.include?('REALM'), 'Expected REALM condition in query'
    assert result.include?(' AND '), 'Expected AND between conditions'
  end

  # ---------------------------------------------------------------------------
  # run_zip — `zip` exit 12 ("nothing to do") must not fail the download
  # ---------------------------------------------------------------------------
  #
  # These drive a REAL `zip`-shaped command rather than stubbing `system`,
  # because the behaviour under test is entirely about the exit status `system`
  # leaves in `$?` — a stub sets no status at all, so it cannot distinguish 12
  # from 1 from success. `without_leaking_child_status` keeps those statuses out
  # of the main thread and therefore out of the rest of the suite.

  # Replaces `system` with one that really runs `sh -c "exit <status>"`, so `$?`
  # is a genuine Process::Status for the code under test to read.
  def run_zip_exiting_with(status)
    gen = generator
    gen.define_singleton_method(:system) { |*_args, **_opts| Kernel.system("exit #{status}") }
    without_leaking_child_status { gen.send(:run_zip, "-j ./out.zip ./in.csv") }
  end

  test 'run_zip returns true when zip succeeds' do
    assert_equal true, run_zip_exiting_with(0)
  end

  # The whole point of the exit-12 handling: an archive left in tmp/ by an
  # earlier attempt makes `zip` report "nothing to do" for files it already
  # holds. Treating that as a failure marked the download failed AND left the
  # stale archive in place, so every retry failed identically and that
  # identifier could never be downloaded again.
  test 'run_zip treats exit 12 (nothing to do) as success' do
    assert_equal true, run_zip_exiting_with(Download::Generators::Base::ZIP_NOTHING_TO_DO)
  end

  test 'run_zip returns false for a genuine zip error' do
    assert_equal false, run_zip_exiting_with(1)
  end

  # `system` returns false without touching `$?` when it is stubbed, which is
  # most of this suite. Reading `$?.success?` blind used to raise NoMethodError
  # on nil there, turning every such test into an error.
  test 'run_zip returns false rather than raising when no status was recorded' do
    gen = generator
    gen.stubs(:system).returns(false)

    assert_equal false, gen.send(:run_zip, '-j ./out.zip ./in.csv')
  end

  test 'run_zip passes chdir through to system' do
    gen = generator
    gen.expects(:system).with('zip -ru ./out.zip *', chdir: '/tmp').returns(true)

    assert_equal true, gen.send(:run_zip, '-ru ./out.zip *', chdir: '/tmp')
  end

  test 'add_conditions uses AND semantics across filter groups for flat shape' do
    gen = Download::Generators::Base.new('./none.zip', {
      iso3: ['GBR'],
      is_marine: true,
      iucn_categories: ['Ia']
    })
    result = gen.send(:add_conditions, 'SELECT * FROM v', [])
    assert result.include?('ISO3')
    assert result.include?('REALM')
    assert result.include?('IUCN_CAT')
    assert result.include?(' AND ')
  end
end
