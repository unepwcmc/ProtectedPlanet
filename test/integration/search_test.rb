# coding: utf-8
require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest

  def setup
    # ES and WebMock don't get along
    WebMock.disable!
    @psi = Search::Index.new 'protectedareas_test', ProtectedArea.all
    @csi = Search::Index.new 'countries_test', Country.without_geometry.all
  end

  def teardown
    @psi.delete
    @csi.delete
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
    value = aggs[name].select{|agg| agg[:label] == value}.count
    assert_equal expected, value
  end

  
  test 'Index single country' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    assert_index 1, 0
  end

  test 'search single country on name' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    assert_index 1, 0
    search = Search.search 'land', {}, 'countries_test'
    assert_equal 1, search.results.count
  end

  test 'search no country results' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    assert_index 1, 0
    search = Search.search 'nonexistent', {}, 'countries_test'
    assert_equal 0, search.results.count
  end

  
  test 'search single country on region' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    assert_index 1, 0
    search = Search.search 'north', {}, 'countries_test'
    assert_equal 1, search.results.count
  end

  test 'search single country on iso3' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    assert_index 1, 0
    search = Search.search 'MBN', {}, 'countries_test'
    assert_equal 1, search.results.count
  end
    
  test 'rank iso3 above country, above region' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    region2 = FactoryGirl.create(:region, id: 988, name: 'Bel')
    # make sure they aren't in index/id order so we are truly sorting
    region_match = FactoryGirl.create(:country, id: 125, iso_3: 'CHE', name: 'Cheese', region: region2)

    iso3_match = FactoryGirl.create(:country, id: 127, iso_3: 'BEL', name: 'Benland', region: region)
    country_match = FactoryGirl.create(:country, id: 124, iso_3: 'BLA', name: 'Bel', region: region)


    assert_index 3, 0

    search = Search.search 'bel', {}, 'countries_test'
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
    search = Search.search 'forest', {}, 'protectedareas_test'
    assert_equal 1, search.results.count
  end
  
  test 'search single ProtectedArea on country name' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    
    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", countries: [country])
    
    assert_index 1, 1
    search = Search.search 'land', {}, 'protectedareas_test'
    assert_equal 1, search.results.count
  end

  test 'search single ProtectedArea on region name' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    
    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", countries: [country])
    
    assert_index 1, 1
    search = Search.search 'north', {}, 'protectedareas_test'
    assert_equal 1, search.results.count
  end

  test 'search single ProtectedArea on region name with params to restrict to one of two PAs' do
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
    search = Search.search 'north', params, 'protectedareas_test'
    byebug
    assert_equal 1, search.results.count
  end  
  
  test 'search single ProtectedArea on region name with params to return both of two PAs' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    iucn_category = FactoryGirl.create(:iucn_category, name: "Ia")
    
    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", wdpa_id: 1, countries: [country], iucn_category: iucn_category)
    pa = FactoryGirl.create(:protected_area, name: "Badger Forest", wdpa_id: 3, countries: [country], iucn_category: iucn_category)
    
    params = {
      filters:
        {
          iucn_category_name: "Ia"
        }
    }
    
    assert_index 1, 2
    search = Search.search 'north', params, 'protectedareas_test'
    assert_equal 2, search.results.count
  end


  test 'search country and  ProtectedArea on match name' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'South Manbone land', region: region)
    country_north = FactoryGirl.create(:country, id: 124, iso_3: 'MBN', name: 'North Manbone land', region: region)
    
    pa = FactoryGirl.create(:protected_area, name: "South Protected Forest", countries: [country_north])

    assert_index 2, 1

    search = Search.search 'south', {}
    assert_equal 2, search.results.count
  end

  test 'search single ProtectedArea on region name with designation params to restrict to one of two PAs' do
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
    search = Search.search 'north', params, 'protectedareas_test'
    assert_equal 1, search.results.count
  end  

  test 'search with marine aggregation' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    pa1 = FactoryGirl.create(:protected_area, name: "Protected Forest", wdpa_id: 1, countries: [country], marine: true)
    pa2 = FactoryGirl.create(:protected_area, name: "Blue Forest", wdpa_id: 3, countries: [country], marine: false)
    
    assert_index 1, 2
    search = Search.search 'forest', {}, 'protectedareas_test'

    assert_aggregation 1, 'type_of_territory', 'Marine', search.aggregations
    assert_aggregation 1, 'type_of_territory', 'Terrestrial', search.aggregations

  end  

  
end
