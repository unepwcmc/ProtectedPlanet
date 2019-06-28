# coding: utf-8
require 'test_helper'

class SearchPageTest < ActionDispatch::IntegrationTest
  test 'search without query or filter redirects to home page' do

    get '/search'

    assert_redirected_to "/"
  end

  test 'search query that returns no results returns success' do
    WebMock.disable!
    get '/search?q=nonexistent'
    assert_response :success
    assert_select "h1", "No results found"
  end
  

  test 'search query that returns single country returns success' do
    WebMock.disable!
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    begin
      si = Search::Index.new 'countries_test', Country.without_geometry.all
      si.index
      sleep(1)
      assert_equal 1, si.count

    get '/search?q=land'
    assert_response :success
    assert_select "h3", "Manbone land"
    ensure
      si.delete
    end

  end

  
end
