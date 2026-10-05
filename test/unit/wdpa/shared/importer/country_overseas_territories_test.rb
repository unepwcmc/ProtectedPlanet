require 'test_helper'

# Characterization for the overseas-territories importer (was ~9%). Reads a parent→children
# ISO3 CSV and wires Country parent-child relationships. CSV is stubbed; countries are real.
class Wdpa::Shared::Importer::CountryOverseasTerritoriesTest < ActiveSupport::TestCase
  Importer = Wdpa::Shared::Importer::CountryOverseasTerritories

  def stub_csv(rows)
    # rows here are the *data* rows; the importer shifts a header off the top.
    CSV.stubs(:read).returns([%w[parent children]] + rows)
  end

  test 'creates parent-child relationships from the CSV' do
    parent = FactoryBot.create(:country, iso_3: 'FRA')
    c1 = FactoryBot.create(:country, iso_3: 'GLP')
    c2 = FactoryBot.create(:country, iso_3: 'MTQ')
    stub_csv([['FRA', 'GLP;MTQ']])

    result = Importer.update_live_table
    assert_equal 2, result[:imported_count]
    assert_equal %w[GLP MTQ].sort, parent.reload.children.map(&:iso_3).sort
    assert_equal [c1, c2].map(&:id).sort, parent.children.map(&:id).sort
  end

  test 'records parent countries that are not found and imports nothing for them' do
    stub_csv([['ZZZ', 'GLP']])
    result = Importer.update_live_table
    assert_equal 0, result[:imported_count]
    assert_includes result[:info][:parent_country_not_found], 'ZZZ'
  end

  test 'records child countries that are not found' do
    FactoryBot.create(:country, iso_3: 'FRA')
    stub_csv([['FRA', 'ZZZ']])
    result = Importer.update_live_table
    assert_equal 0, result[:imported_count]
    assert_includes result[:info][:child_country_not_found], 'ZZZ'
  end

  test 'skips relationships that already exist' do
    parent = FactoryBot.create(:country, iso_3: 'FRA')
    child  = FactoryBot.create(:country, iso_3: 'GLP')
    parent.children << child # pre-existing
    stub_csv([['FRA', 'GLP']])

    result = Importer.update_live_table
    assert_equal 0, result[:imported_count]
    assert_equal 1, result[:info][:already_added_so_skipped]
  end
end
