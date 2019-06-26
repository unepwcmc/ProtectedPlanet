# coding: utf-8
require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  test 'Index single country' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)

    # ES and WebMock don't get along
    WebMock.disable!

    si = Search::Index.new 'countries_test', Country.without_geometry.all
    byebug
    
    si.index
    
    assert_equal 1, si.count
    si.delete
  end

end
