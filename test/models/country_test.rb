require 'test_helper'

class CountryTest < ActiveSupport::TestCase
  test '.bounds returns the bounding box for the Country geometry' do
    country = FactoryBot.create(:country, bounding_box: 'POLYGON ((-1 0, 0 1, 1 2, 1 0, -1 0))')

    assert_equal [[0, -1], [2, 1]], country.bounds
  end

  test '.without_geometry does not select the geometry columns' do
    country = FactoryBot.create(:country)

    selected_country = Country.without_geometry.find(country.id)

    refute selected_country.has_attribute?(:bounding_box)
  end

  test '.as_indexed_json returns the Country as JSON' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, name: 'Manboneland', region: region)

    expected_json = {
      "id" => 123,
      "name" => 'Manboneland',
      "iso_3"=> 'MTX',
      "region_for_index" => {
        "name" => "North Manmerica"
      }
    }

    assert_equal expected_json, country.as_indexed_json
  end

  test '.protected_areas returns the number of Protected Areas in the country' do
    country = FactoryBot.create(:country)

    expected_pas = [
      FactoryBot.create(:protected_area, countries: [country]),
      FactoryBot.create(:protected_area, countries: [country])
    ]

    FactoryBot.create(:protected_area)

    protected_areas = country.protected_areas

    assert_equal 2, protected_areas.count
    assert_same_elements expected_pas.map(&:id), protected_areas.pluck(:id)
  end

  test ".designations returns the designations for the Country's Protected Areas" do
    designation_1 = FactoryBot.create(:designation, name: 'Lionel Messi')
    designation_2 = FactoryBot.create(:designation, name: 'Robin Van Persie')
    designation_3 = FactoryBot.create(:designation, name: 'Cristiano Ronaldo')

    country_1 = FactoryBot.create(:country)
    country_2 = FactoryBot.create(:country)
    country_3 = FactoryBot.create(:country)

    FactoryBot.create(:protected_area, designation: designation_1, countries: [country_1])
    FactoryBot.create(:protected_area, designation: designation_2, countries: [country_1])
    FactoryBot.create(:protected_area, designation: designation_2, countries: [country_2])
    FactoryBot.create(:protected_area, designation: designation_3, countries: [country_3])

    assert_equal 2, country_1.designations.count
  end

  test '#data_providers returns all countries that provide PA data' do
    country_1 = FactoryBot.create(:country)
    country_2 = FactoryBot.create(:country)
    FactoryBot.create(:country)

    FactoryBot.create(:protected_area, countries: [country_1])
    FactoryBot.create(:protected_area, countries: [country_2])

    assert_equal 2, Country.data_providers.count
  end

  test '#random_protected_areas, given an integer, returns the given number of random pas' do
    country = FactoryBot.create(:country)
    country_pas = 2.times.map{ FactoryBot.create(:protected_area, countries: [country]) }
    2.times{ FactoryBot.create(:protected_area) }

    random_pas = country.random_protected_areas 2
    assert_same_elements country_pas, random_pas
  end

  test '#protected_areas_per_designation returns groups of pa counts per designation' do
    # The query groups by designations.name and SUMs, so the designations need
    # distinct names (the factory default is the same for both). SUM() over an
    # integer column is numeric in Postgres, and since Rails 6.1 / pg 1.x the
    # raw result is decoded to BigDecimal rather than handed back as a string.
    designation_1 = FactoryBot.create(:designation, name: 'Alpha')
    designation_2 = FactoryBot.create(:designation, name: 'Beta')
    country = FactoryBot.create(:country)
    expected_groups = [{
      'designation_name' => 'Alpha',
      'count' => BigDecimal('2')
    }, {
      'designation_name' => 'Beta',
      'count' => BigDecimal('3')
    }]

    2.times { FactoryBot.create(:protected_area, countries: [country], designation: designation_1) }
    3.times { FactoryBot.create(:protected_area, countries: [country], designation: designation_2) }

    assert_same_elements expected_groups, country.protected_areas_per_designation.to_a
  end

  test '#protected_areas_per_iucn_category returns groups of pa counts per iucn_category' do
    iucn_category_1 = FactoryBot.create(:iucn_category, name: 'Ib')
    iucn_category_2 = FactoryBot.create(:iucn_category, name: 'V')
    country = FactoryBot.create(:country)
    expected_groups = [{
      'iucn_category_id' => iucn_category_1.id,
      'iucn_category_name' => iucn_category_1.name,
      'count' => 2,
      # round(..., 2) is numeric, decoded to BigDecimal since Rails 6.1 / pg 1.x.
      'percentage' => BigDecimal('40')
    }, {
      'iucn_category_id' => iucn_category_2.id,
      'iucn_category_name' => iucn_category_2.name,
      'count' => 3,
      'percentage' => BigDecimal('60')
    }]

    2.times { FactoryBot.create(:protected_area, countries: [country], iucn_category: iucn_category_1) }
    3.times { FactoryBot.create(:protected_area, countries: [country], iucn_category: iucn_category_2) }

    assert_same_elements expected_groups, country.protected_areas_per_iucn_category.to_a
  end

  test '#protected_areas_per_governance returns groups of pa counts per governance' do
    governance_1 = FactoryBot.create(:governance, name: 'Regional')
    governance_2 = FactoryBot.create(:governance, name: 'International')
    country = FactoryBot.create(:country)
    expected_groups = [{
      'governance_id' => governance_1.id,
      'governance_name' => governance_1.name,
      'governance_type' => nil,
      'count' => 2,
      # round(..., 2) is numeric, decoded to BigDecimal since Rails 6.1 / pg 1.x.
      'percentage' => BigDecimal('40')
    }, {
      'governance_id' => governance_2.id,
      'governance_name' => governance_2.name,
      'governance_type' => nil,
      'count' => 3,
      'percentage' => BigDecimal('60')
    }]

    2.times { FactoryBot.create(:protected_area, countries: [country], governance: governance_1) }
    3.times { FactoryBot.create(:protected_area, countries: [country], governance: governance_2) }

    assert_same_elements expected_groups, country.protected_areas_per_governance.to_a
  end

  # The local dev database is PostgreSQL 11 and production is PostgreSQL 10, where
  # an unaliased EXTRACT(...) is implicitly named `date_part`. PostgreSQL 14
  # renamed it to `extract`, so on the PG 17 staging database this query raised
  # "PG::UndefinedColumn: column \"date_part\" does not exist" -- and because
  # ApplicationController rescues it, EVERY country page silently 302'd to the
  # homepage instead of erroring.
  #
  # A purely functional assertion cannot guard this: on PG 11 the old SQL works
  # fine, so the test would pass while staging stayed broken. Assert the SQL shape
  # instead, which holds on every PostgreSQL version.
  test '#coverage_growth does not depend on PostgreSQL\'s implicit EXTRACT column name' do
    country = FactoryBot.create(:country)

    sql = country.send(:protected_areas_inner_join,
                       'EXTRACT(year from legal_status_updated_at)',
                       false,
                       alias_as: Country::YEAR_COLUMN)

    assert_includes sql, "AS #{Country::YEAR_COLUMN}",
                    'the grouped expression must be aliased explicitly'
    assert_includes sql, 'GROUP BY EXTRACT(year from legal_status_updated_at)',
                    'GROUP BY keeps the raw expression -- "GROUP BY <expr> AS <name>" is invalid SQL'
  end

  test '#coverage_growth runs against the real database' do
    country = FactoryBot.create(:country)

    rows = nil
    assert_nothing_raised { rows = country.send(:coverage_growth, false).to_a }
    assert_kind_of Array, rows
  end

  test 'protected_areas_inner_join stays unaliased for plain column callers' do
    country = FactoryBot.create(:country)

    sql = country.send(:protected_areas_inner_join, :designation_id, false)

    assert_includes sql, 'SELECT designation_id,'
    # The COUNT(...) AS count alias is always there; what must NOT appear is an
    # alias on the grouped column itself.
    refute_includes sql, 'designation_id AS'
  end
end
