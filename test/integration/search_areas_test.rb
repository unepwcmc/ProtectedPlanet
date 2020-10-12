# coding: utf-8
require 'test_helper'

class SearchAreasTest < ActionDispatch::IntegrationTest

  def setup
    # ES and WebMock don't get along
    WebMock.disable!
    # need some data to force index/field creation but don't want it to be found in test searches
    region = FactoryGirl.create(:region, id: 999, name: 'jsdfasdf')
    country = FactoryGirl.create(:country, id: 999, iso_3: 'jsd', name: 'jsdjkjkasdhf', region: region)
    pa = FactoryGirl.create(:protected_area, name: "skdfhshdf", countries: [country], marine: false, has_parcc_info: false, is_green_list: false, has_irreplaceability_info: false)

    @psi = Search::Index.new Search::PA_INDEX, ProtectedArea.all
    @psi.create
    @csi = Search::Index.new Search::COUNTRY_INDEX, Country.without_geometry.all
    @csi.create

    seed_cms
    
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

  
  test 'search without query or filter loads page' do
    get '/en/search-areas'
    assert_response :success
  end

  test 'search query with loads page' do
    get '/en/search-areas?search_term=nonexistent'
    assert_response :success
  end
  
  # test json endpoint for ajax search
  test 'search query that would hit country, doesnt as we dont return countries in main search' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone', region: region)
    assert_index 2, 1

    get '/en/search-areas-results?geo_type=site&search_term=Manbone'
    assert_response :success
    json = JSON.parse response.body
    assert_equal 0, json['areas']['total']
  end

  test 'search query that returns single protected area returns success' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", countries: [country])
    assert_index 2, 2

    get '/en/search-areas-results?geo_type=site&search_term=forest'

    assert_response :success
    json = JSON.parse response.body
    assert_equal 1, json['areas']['total']
  end

  test 'search query that matches PA and country only returns PA' do

    region = FactoryGirl.create(:region, id: 987, name: 'Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'North Manbone land', region: region)
    pa = FactoryGirl.create(:protected_area, name: "North Protected Forest", countries: [country])
    assert_index 2, 2

    get '/en/search-areas-results?geo_type=site&search_term=north'

    assert_response :success
    json = JSON.parse response.body
    assert_equal 1, json['areas']['total']
  end
end
