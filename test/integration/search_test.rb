# coding: utf-8
require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  test 'Index single country' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    # ES and WebMock don't get along
    WebMock.disable!
    begin
      si = Search::Index.new 'countries_test', Country.without_geometry.all
      si.index
      sleep(1)
      assert_equal 1, si.count
    ensure
      si.delete
    end
  end

  test 'search single country on name' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    # ES and WebMock don't get along
    WebMock.disable!
    begin
      si = Search::Index.new 'countries_test', Country.without_geometry.all
      si.index
      sleep(1)
      assert_equal 1, si.count
      search = Search.search 'land', {}, 'countries_test'
      assert_equal 1, search.results.count
    ensure
      si.delete
    end
  end

  test 'search no country results' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    # ES and WebMock don't get along
    WebMock.disable!
    begin
      si = Search::Index.new 'countries_test', Country.without_geometry.all
      si.index
      sleep(1)
      assert_equal 1, si.count
      search = Search.search 'nonexistent', {}, 'countries_test'
      assert_equal 0, search.results.count
    ensure
      si.delete
    end
  end

  
  test 'search single country on region' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    # ES and WebMock don't get along
    WebMock.disable!
    begin
      si = Search::Index.new 'countries_test', Country.without_geometry.all
      si.index
      sleep(1)
      assert_equal 1, si.count
      search = Search.search 'north', {}, 'countries_test'
      assert_equal 1, search.results.count
    ensure
      si.delete
    end
  end

    test 'search single country on iso3' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    # ES and WebMock don't get along
    WebMock.disable!
    begin
      si = Search::Index.new 'countries_test', Country.without_geometry.all
      si.index
      sleep(1)
      assert_equal 1, si.count
      search = Search.search 'MBN', {}, 'countries_test'
      assert_equal 1, search.results.count
    ensure
      si.delete
    end
  end
    
    test 'rank iso3 above country, above region' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    region2 = FactoryGirl.create(:region, id: 988, name: 'Bel')
    # make sure they aren't in index/id order so we are truly sorting
    region_match = FactoryGirl.create(:country, id: 125, iso_3: 'CHE', name: 'Cheese', region: region2)

    iso3_match = FactoryGirl.create(:country, id: 127, iso_3: 'BEL', name: 'Benland', region: region)
    country_match = FactoryGirl.create(:country, id: 124, iso_3: 'BLA', name: 'Bel', region: region)


    # ES and WebMock don't get along
    WebMock.disable!
    begin
      si = Search::Index.new 'countries_test', Country.without_geometry.all
      si.index
      sleep(1)
      assert_equal 3, si.count
      search = Search.search 'bel', {}, 'countries_test'
      assert_equal 3, search.results.count
      assert_equal iso3_match.id, search.results.matches[0]["_source"]["id"]
      assert_greater search.results.matches[0]['_score'], search.results.matches[1]['_score']
      assert_equal country_match.id, search.results.matches[1]["_source"]["id"]
      assert_greater search.results.matches[1]['_score'], search.results.matches[2]['_score']
      assert_equal region_match.id, search.results.matches[2]["_source"]["id"]
    ensure
      si.delete
    end
  end

  test 'Index single ProtectedArea' do
    pa = FactoryGirl.create(:protected_area)

    # ES and WebMock don't get along
    WebMock.disable!
    begin
      si = Search::Index.new 'protectedareas_test', ProtectedArea.all
      si.index
      sleep(1)
      assert_equal 1, si.count
    ensure
      si.delete
    end

  end

  test 'search single ProtectedArea on name, no country' do

    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", countries: [])

    # ES and WebMock don't get along
    WebMock.disable!
    begin
      si = Search::Index.new 'protectedareas_test', ProtectedArea.all
      si.index
      sleep(1)
      assert_equal 1, si.count
      search = Search.search 'forest', {}, 'protectedareas_test'
      assert_equal 1, search.results.count
    ensure
      si.delete
    end
  end
  
  test 'search single ProtectedArea on country name' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    
    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", countries: [country])
    
    # ES and WebMock don't get along
    WebMock.disable!
    begin
      si = Search::Index.new 'protectedareas_test', ProtectedArea.all
      si.index
      sleep(1)
      assert_equal 1, si.count
      search = Search.search 'land', {}, 'protectedareas_test'
      assert_equal 1, search.results.count
    ensure
      si.delete
    end
  end

  test 'search single ProtectedArea on region name' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    
    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", countries: [country])
    
    # ES and WebMock don't get along
    WebMock.disable!
    begin
      si = Search::Index.new 'protectedareas_test', ProtectedArea.all
      si.index
      sleep(1)
      assert_equal 1, si.count
      search = Search.search 'north', {}, 'protectedareas_test'
      assert_equal 1, search.results.count
    ensure
      si.delete
    end
  end

  test 'search single ProtectedArea on region name with params to restrict to one of two PAs' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    
    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", wdpa_id: 1, countries: [country])
    pa = FactoryGirl.create(:protected_area, name: "Badger Forest", wdpa_id: 3, countries: [country])
    
    params = {
      wdpa_id: 1
    }
    
    # ES and WebMock don't get along
    WebMock.disable!
    begin
      si = Search::Index.new 'protectedareas_test', ProtectedArea.all
      si.index
      sleep(1)
      assert_equal 1, si.count
      search = Search.search 'north', params, 'protectedareas_test'
      assert_equal 1, search.results.count
    ensure
      si.delete
    end
  end  
  
  
end
