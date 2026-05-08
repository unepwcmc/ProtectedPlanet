require 'test_helper'

class DownloadGeneratorsBaseTest < ActiveSupport::TestCase
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
