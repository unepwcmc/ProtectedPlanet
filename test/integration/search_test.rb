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

  
end
