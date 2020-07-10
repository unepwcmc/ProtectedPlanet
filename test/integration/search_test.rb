# coding: utf-8
require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest

  def setup
    # ES and WebMock don't get along
    WebMock.disable!
    @psi = Search::Index.new Search::PA_INDEX, ProtectedArea.all
    @psi.create
    @csi = Search::Index.new Search::COUNTRY_INDEX, Country.without_geometry.all
    @csi.create
  end

  def teardown
    @psi.delete
    @csi.delete
    WebMock.enable!
  end
  
  def assert_index num_countries, num_pas
    @psi.index
    @csi.index
    sleep(1)

    # ES only creates an index if it is used
    if(num_countries > 0)
      assert_equal num_countries, @csi.count
    end
    if(num_pas > 0)
      assert_equal num_pas, @psi.count
    end
  end
  
  def assert_aggregation expected, name, value, aggs
    actual = aggs[name].select{|agg| agg[:label] == value}[0][:count]
    assert_equal expected, actual
  end

  
  test 'Index single country' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    assert_index 1, 0
  end

  test 'search single country on whole name' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    assert_index 1, 0
    search = Search.search 'manbone land', {}, Search::COUNTRY_INDEX
    assert_equal 1, search.results.count
  end

  test 'search no country results' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    assert_index 1, 0
    search = Search.search 'nonexistent', {}, Search::COUNTRY_INDEX
    assert_equal 0, search.results.count
  end

  test 'search single country on iso3' do
    skip ('currently not searching on iso3')
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    assert_index 1, 0
    search = Search.search 'MBN', {}
    assert_equal 1, search.results.count
  end
    
  test 'rank iso3 above country, above region' do
    skip ('currently not searching on iso3 or region')
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    region2 = FactoryGirl.create(:region, id: 988, name: 'Bel')
    # make sure they aren't in index/id order so we are truly sorting
    region_match = FactoryGirl.create(:country, id: 125, iso_3: 'CHE', name: 'Cheese', region: region2)
    iso3_match = FactoryGirl.create(:country, id: 127, iso_3: 'BEL', name: 'Benland', region: region)
    country_match = FactoryGirl.create(:country, id: 124, iso_3: 'BLA', name: 'Bel', region: region)


    assert_index 3, 0

    search = Search.search 'bel', {}
    assert_equal 3, search.results.count
    assert_equal iso3_match.id, search.results.matches[0]["_source"]["id"]
    assert_greater search.results.matches[0]['_score'], search.results.matches[1]['_score']
    assert_equal country_match.id, search.results.matches[1]["_source"]["id"]
    assert_greater search.results.matches[1]['_score'], search.results.matches[2]['_score']
    assert_equal region_match.id, search.results.matches[2]["_source"]["id"]
  end

  test 'Index single ProtectedArea' do
    pa = FactoryGirl.create(:protected_area)
    assert_index 0, 1
  end

  test 'search single ProtectedArea on name no country' do
    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", countries: [])

    assert_index 0, 1
    search = Search.search 'forest', {}
    assert_equal 1, search.results.count
  end
  

  test 'search single ProtectedArea on wdpa name' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    
    pa = FactoryGirl.create(:protected_area, wdpa_id: 999, name: "Protected Forest", countries: [country])
    
    assert_index 1, 1
    search = Search.search '999', {}
    assert_equal 1, search.results.count
  end


  test 'search single ProtectedArea on name with params to restrict to one of two PAs' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    
    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", wdpa_id: 1, countries: [country])
    pa = FactoryGirl.create(:protected_area, name: "Badger Forest", wdpa_id: 3, countries: [country])
    
    params = {
      filters:
        {
          wdpa_id: 1
        }
    }
    
    assert_index 1, 2
    search = Search.search 'forest', params
    assert_equal 1, search.results.count
  end  
  
  test 'search single ProtectedArea on name with params to return two PAs' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    iucn_category = FactoryGirl.create(:iucn_category, name: "Ia", id:1)
    iucn_category2 = FactoryGirl.create(:iucn_category, name: "II", id:2)
    
    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", wdpa_id: 1, countries: [country], iucn_category: iucn_category)
    pa = FactoryGirl.create(:protected_area, name: "Badger Forest", wdpa_id: 2, countries: [country], iucn_category: iucn_category)
    pa = FactoryGirl.create(:protected_area, name: "Warthog Forest", wdpa_id: 3, countries: [country], iucn_category: iucn_category2)
    
    params = {
      filters:
        {
          iucn_category: "Ia"
        }
    }
    
    assert_index 1, 3
    search = Search.search 'forest', params
    assert_equal 2, search.results.count
    assert_aggregation 2, 'iucn_category', 'Ia', search.aggregations
  end



  test 'search ProtectedArea on  name with designation params to restrict to one of two PAs' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    jurisdiction = FactoryGirl.create(:jurisdiction, id: 2, name: 'International')
    designation = FactoryGirl.create(:designation, id: 654, name: 'National', jurisdiction: jurisdiction)

    pa1 = FactoryGirl.create(:protected_area, name: "Protected Forest", wdpa_id: 1, countries: [country], designation: designation)
    pa2 = FactoryGirl.create(:protected_area, name: "Badger Forest", wdpa_id: 3, countries: [country])
    
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
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    iucn_category = FactoryGirl.create(:iucn_category, name: "Ia", id:1)
    iucn_category2 = FactoryGirl.create(:iucn_category, name: "II", id:2)

    pa1 = FactoryGirl.create(:protected_area, name: "Protected Forest", wdpa_id: 1, countries: [country], iucn_category: iucn_category)
    pa2 = FactoryGirl.create(:protected_area, name: "Blue Forest", wdpa_id: 2, countries: [country], iucn_category: iucn_category2)
    pa3 = FactoryGirl.create(:protected_area, name: "Bob Forest", wdpa_id: 3, countries: [country],iucn_category: iucn_category2)
    
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
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country1 = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    country2 = FactoryGirl.create(:country, id: 124, iso_3: 'MBA', name: 'Ant land', region: region)

    pa1 = FactoryGirl.create(:protected_area, name: "Protected Forest", wdpa_id: 1, countries: [country1])
    pa2 = FactoryGirl.create(:protected_area, name: "Blue Forest", wdpa_id: 2, countries: [country2])
    pa3 = FactoryGirl.create(:protected_area, name: "Bob Forest", wdpa_id: 3, countries: [country2])
    
    assert_index 2, 3
    search = Search.search 'forest', {}
    assert_aggregation 1, 'country', 'Manbone land', search.aggregations
    assert_aggregation 2, 'country', 'Ant land', search.aggregations
  end  

  test 'search with country filter' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country1 = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    country2 = FactoryGirl.create(:country, id: 124, iso_3: 'MBA', name: 'Ant land', region: region)

    pa1 = FactoryGirl.create(:protected_area, name: "Protected Forest", wdpa_id: 1, countries: [country1])
    pa2 = FactoryGirl.create(:protected_area, name: "Blue Forest", wdpa_id: 2, countries: [country2])
    pa3 = FactoryGirl.create(:protected_area, name: "Bob Forest", wdpa_id: 3, countries: [country2])
    
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
      region1 = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
      region2 = FactoryGirl.create(:region, id: 986, name: 'South Manmerica')
      country1 = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region1)
      country2 = FactoryGirl.create(:country, id: 124, iso_3: 'MBA', name: 'Ant land', region: region2)
      country3 = FactoryGirl.create(:country, id: 125, iso_3: 'MBA', name: 'Badger land', region: region2)
      
      pa1 = FactoryGirl.create(:protected_area, name: "Protected Forest", wdpa_id: 1, countries: [country1])
      pa2 = FactoryGirl.create(:protected_area, name: "Blue Forest", wdpa_id: 2, countries: [country2])
      pa3 = FactoryGirl.create(:protected_area, name: "Bob Forest", wdpa_id: 3, countries: [country3])
      
      assert_index 3, 3
      search = Search.search 'forest', {}
      assert_aggregation 1, 'region', 'North Manmerica', search.aggregations
      assert_aggregation 2, 'region', 'South Manmerica', search.aggregations
  end  

    # a bunch of tests to check stemming/fuzzy/partial matching is sane
    
  test 'search single country on stemmed query' do
    region = FactoryGirl.create(:region, id: 987, name: 'Europe')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'BEL', name: 'Belgium', region: region)

    assert_index 1, 0
    search = Search.search 'belgiums', {}, Search::COUNTRY_INDEX
    assert_equal 1, search.results.count
  end

  test 'search single country on one word of two word name' do
    region = FactoryGirl.create(:region, id: 987, name: 'Europe')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'BEL', name: 'United States', region: region)

    assert_index 1, 0
    search = Search.search 'United', {}, Search::COUNTRY_INDEX
    assert_equal 1, search.results.count
  end

  test 'search single country on stemmed version of name' do
    region = FactoryGirl.create(:region, id: 987, name: 'Europe')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'BEL', name: 'United States', region: region)

    assert_index 1, 0
    search = Search.search 'Unite', {}, Search::COUNTRY_INDEX
    assert_equal 1, search.results.count
  end


  test 'search areas on stemmed name both-ways-round' do
    region = FactoryGirl.create(:region, id: 987, name: 'Europe')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'BEL', name: 'Belgium', region: region)
      pa1 = FactoryGirl.create(:protected_area, name: "Protected Forest", wdpa_id: 1, countries: [country])
      pa2 = FactoryGirl.create(:protected_area, name: "Blue Forests", wdpa_id: 2, countries: [country])

    assert_index 1, 2
    search = Search.search 'forest', {}
    assert_equal 2, search.results.count
    
    search = Search.search 'forests', {}
    assert_equal 2, search.results.count
  end


  test 'search area on poor-fuzzy-match should not hit' do
    region = FactoryGirl.create(:region, id: 987, name: 'Europe')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'BEL', name: 'Belgium', region: region)
      pa1 = FactoryGirl.create(:protected_area, name: "Badger Forest", wdpa_id: 1, countries: [country])
      pa2 = FactoryGirl.create(:protected_area, name: "Bodger Forests", wdpa_id: 2, countries: [country])

    assert_index 1, 2
    search = Search.search 'badgers', {}
    assert_equal 1, search.results.count
  end


  
end
