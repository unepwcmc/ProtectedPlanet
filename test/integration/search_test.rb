require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  def setup
    # ES and WebMock don't get along
    WebMock.disable!
    @psi = fresh_search_index Search::PA_INDEX, ProtectedArea.all
    @csi = fresh_search_index Search::COUNTRY_INDEX, Country.without_geometry.all
    # The default search index set now includes the region index (Search::AREAS_INDEX);
    # it must exist or multi-index queries 404 with "no such index [regions_test]".
    @rsi = fresh_search_index Search::REGION_INDEX, Region.without_geometry.all
    # DEFAULT_INDEX_NAME also queries the CMS index; it must exist too (empty is fine).
    @cmsi = fresh_search_index Search::CMS_INDEX, Comfy::Cms::SearchablePage.all
  end

  def teardown
    @psi&.delete
    @csi&.delete
    @rsi&.delete
    @cmsi&.delete
    WebMock.enable!
  end

  def assert_index(num_countries, num_pas)
    @psi.index
    @csi.index
    @rsi.index
    sleep(1)

    # ES only creates an index if it is used
    assert_equal num_countries, @csi.count if num_countries > 0
    return unless num_pas > 0

    assert_equal num_pas, @psi.count
  end

  def assert_aggregation(expected, name, value, aggs)
    actual = aggs[name].select { |agg| agg[:label] == value }[0][:count]
    assert_equal expected, actual
  end

  test 'Index single country' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    assert_index 1, 0
  end

  test 'search single country on whole name' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    assert_index 1, 0
    search = Search.search 'manbone land', {}, Search::COUNTRY_INDEX
    assert_equal 1, search.results.count
  end

  test 'search no country results' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    assert_index 1, 0
    search = Search.search 'nonexistent', {}, Search::COUNTRY_INDEX
    assert_equal 0, search.results.count
  end

  test 'Index single ProtectedArea' do
    pa = FactoryBot.create(:protected_area)
    assert_index 0, 1
  end

  test 'search single ProtectedArea on name no country' do
    pa = FactoryBot.create(:protected_area, name: 'Protected Forest', countries: [])

    assert_index 0, 1
    search = Search.search 'forest', {}
    assert_equal 1, search.results.count
  end

  test 'search single ProtectedArea on wdpa name' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    pa = FactoryBot.create(:protected_area, site_id: 999, name: 'Protected Forest', countries: [country])

    assert_index 1, 1
    search = Search.search '999', {}
    assert_equal 1, search.results.count
  end

  test 'search single ProtectedArea on name with params to restrict to one of two PAs' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    pa = FactoryBot.create(:protected_area, name: 'Protected Forest', site_id: 1, countries: [country])
    pa = FactoryBot.create(:protected_area, name: 'Badger Forest', site_id: 3, countries: [country])

    params = {
      filters:
        {
          site_id: 1
        }
    }

    assert_index 1, 2
    search = Search.search 'forest', params
    assert_equal 1, search.results.count
  end

  test 'search single ProtectedArea on name with params to return two PAs' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    iucn_category = FactoryBot.create(:iucn_category, name: 'Ia', id: 1)
    iucn_category2 = FactoryBot.create(:iucn_category, name: 'II', id: 2)

    pa = FactoryBot.create(:protected_area, name: 'Protected Forest', site_id: 1, countries: [country],
      iucn_category: iucn_category)
    pa = FactoryBot.create(:protected_area, name: 'Badger Forest', site_id: 2, countries: [country],
      iucn_category: iucn_category)
    pa = FactoryBot.create(:protected_area, name: 'Warthog Forest', site_id: 3, countries: [country],
      iucn_category: iucn_category2)

    params = {
      filters:
        {
          iucn_category: 'Ia'
        }
    }

    assert_index 1, 3
    search = Search.search 'forest', params
    assert_equal 2, search.results.count
    assert_aggregation 2, 'iucn_category', 'Ia', search.aggregations
  end

  test 'search ProtectedArea on  name with designation params to restrict to one of two PAs' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    jurisdiction = FactoryBot.create(:jurisdiction, id: 2, name: 'International')
    designation = FactoryBot.create(:designation, id: 654, name: 'National', jurisdiction: jurisdiction)

    pa1 = FactoryBot.create(:protected_area, name: 'Protected Forest', site_id: 1, countries: [country],
      designation: designation)
    pa2 = FactoryBot.create(:protected_area, name: 'Badger Forest', site_id: 3, countries: [country])

    params = {
      filters:
        {
          designation: 'National'
        }
    }

    assert_index 1, 2
    search = Search.search 'forest', params
    assert_equal 1, search.results.count
  end

  test 'search with iucn_category filter' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    iucn_category = FactoryBot.create(:iucn_category, name: 'Ia', id: 1)
    iucn_category2 = FactoryBot.create(:iucn_category, name: 'II', id: 2)

    pa1 = FactoryBot.create(:protected_area, name: 'Protected Forest', site_id: 1, countries: [country],
      iucn_category: iucn_category)
    pa2 = FactoryBot.create(:protected_area, name: 'Blue Forest', site_id: 2, countries: [country],
      iucn_category: iucn_category2)
    pa3 = FactoryBot.create(:protected_area, name: 'Bob Forest', site_id: 3, countries: [country],
      iucn_category: iucn_category2)

    assert_index 1, 3
    params = {
      filters:
        {
          iucn_category: 'II'
        }
    }

    search = Search.search 'forest', params
    assert_equal 2, search.results.count
    assert_aggregation 2, 'iucn_category', 'II', search.aggregations
  end

  test 'search with country aggregation' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country1 = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    country2 = FactoryBot.create(:country, id: 124, iso_3: 'MBA', name: 'Ant land', region: region)

    pa1 = FactoryBot.create(:protected_area, name: 'Protected Forest', site_id: 1, countries: [country1])
    pa2 = FactoryBot.create(:protected_area, name: 'Blue Forest', site_id: 2, countries: [country2])
    pa3 = FactoryBot.create(:protected_area, name: 'Bob Forest', site_id: 3, countries: [country2])

    assert_index 2, 3
    search = Search.search 'forest', {}
    assert_aggregation 1, 'country', 'Manbone land', search.aggregations
    assert_aggregation 2, 'country', 'Ant land', search.aggregations
  end

  test 'search with country filter' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country1 = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    country2 = FactoryBot.create(:country, id: 124, iso_3: 'MBA', name: 'Ant land', region: region)

    pa1 = FactoryBot.create(:protected_area, name: 'Protected Forest', site_id: 1, countries: [country1])
    pa2 = FactoryBot.create(:protected_area, name: 'Blue Forest', site_id: 2, countries: [country2])
    pa3 = FactoryBot.create(:protected_area, name: 'Bob Forest', site_id: 3, countries: [country2])

    assert_index 2, 3
    params = {
      filters:
        {
          country: 'Ant land'
        }
    }

    search = Search.search 'forest', params
    assert_equal 2, search.results.count
    assert_aggregation 2, 'country', 'Ant land', search.aggregations
  end

  test 'search with region aggregation' do
    region1 = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    region2 = FactoryBot.create(:region, id: 986, name: 'South Manmerica')
    country1 = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region1)
    country2 = FactoryBot.create(:country, id: 124, iso_3: 'MBA', name: 'Ant land', region: region2)
    country3 = FactoryBot.create(:country, id: 125, iso_3: 'MBA', name: 'Badger land', region: region2)

    pa1 = FactoryBot.create(:protected_area, name: 'Protected Forest', site_id: 1, countries: [country1])
    pa2 = FactoryBot.create(:protected_area, name: 'Blue Forest', site_id: 2, countries: [country2])
    pa3 = FactoryBot.create(:protected_area, name: 'Bob Forest', site_id: 3, countries: [country3])

    assert_index 3, 3
    search = Search.search 'forest', {}
    assert_aggregation 1, 'region', 'North Manmerica', search.aggregations
    assert_aggregation 2, 'region', 'South Manmerica', search.aggregations
  end

  # a bunch of tests to check stemming/fuzzy/partial matching is sane

  test 'search single country on stemmed query' do
    region = FactoryBot.create(:region, id: 987, name: 'Europe')
    country = FactoryBot.create(:country, id: 123, iso_3: 'BEL', name: 'Belgium', region: region)

    assert_index 1, 0
    search = Search.search 'belgiums', {}, Search::COUNTRY_INDEX
    assert_equal 1, search.results.count
  end

  test 'search single country on one word of two word name' do
    region = FactoryBot.create(:region, id: 987, name: 'Europe')
    country = FactoryBot.create(:country, id: 123, iso_3: 'BEL', name: 'United States', region: region)

    assert_index 1, 0
    search = Search.search 'United', {}, Search::COUNTRY_INDEX
    assert_equal 1, search.results.count
  end

  test 'search single country on stemmed version of name' do
    region = FactoryBot.create(:region, id: 987, name: 'Europe')
    country = FactoryBot.create(:country, id: 123, iso_3: 'BEL', name: 'United States', region: region)

    assert_index 1, 0
    search = Search.search 'Unite', {}, Search::COUNTRY_INDEX
    assert_equal 1, search.results.count
  end

  test 'search areas on stemmed name both-ways-round' do
    region = FactoryBot.create(:region, id: 987, name: 'Europe')
    country = FactoryBot.create(:country, id: 123, iso_3: 'BEL', name: 'Belgium', region: region)
    pa1 = FactoryBot.create(:protected_area, name: 'Protected Forest', site_id: 1, countries: [country])
    pa2 = FactoryBot.create(:protected_area, name: 'Blue Forests', site_id: 2, countries: [country])

    assert_index 1, 2
    search = Search.search 'forest', {}
    assert_equal 2, search.results.count

    search = Search.search 'forests', {}
    assert_equal 2, search.results.count
  end

  test 'search area on poor-fuzzy-match should not hit' do
    region = FactoryBot.create(:region, id: 987, name: 'Europe')
    country = FactoryBot.create(:country, id: 123, iso_3: 'BEL', name: 'Belgium', region: region)
    pa1 = FactoryBot.create(:protected_area, name: 'Badger Forest', site_id: 1, countries: [country])
    pa2 = FactoryBot.create(:protected_area, name: 'Bodger Forests', site_id: 2, countries: [country])

    assert_index 1, 2
    search = Search.search 'badgers', {}
    assert_equal 1, search.results.count
  end
end
