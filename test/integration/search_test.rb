# coding: utf-8
require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  test 'Index single country can be found by name' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    # ES and WebMock don't get along
    WebMock.disable!

    Search::Index.index 'countries', Country.without_geometry.all
    s = Search.search 'land'
    assert_equal 1, s.results.count
  end

end
