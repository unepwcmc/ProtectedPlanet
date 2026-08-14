# coding: utf-8
require 'test_helper'

class SearchPageTest < ActionDispatch::IntegrationTest

  def setup
    # ES and WebMock don't get along
    WebMock.disable!
    # need some data to force index/field creation but don't want it to be found in test searches
    region = FactoryBot.create(:region, id: 999, name: 'jsdfasdf')
    country = FactoryBot.create(:country, id: 999, iso_3: 'jsd', name: 'jsdjkjkasdhf', region: region)
    pa = FactoryBot.create(:protected_area, name: "skdfhshdf", countries: [country], marine: false, has_parcc_info: false, has_irreplaceability_info: false)

    @psi = Search::Index.new Search::PA_INDEX, ProtectedArea.all
    @psi.create
    @csi = Search::Index.new Search::COUNTRY_INDEX, Country.without_geometry.all
    @csi.create
    # Default search also queries the region + CMS indices — they must exist or queries 404.
    @rsi = Search::Index.new Search::REGION_INDEX, Region.without_geometry.all
    @rsi.create
    @cmsi = Search::Index.new Search::CMS_INDEX, Comfy::Cms::SearchablePage.all
    @cmsi.create

    seed_cms
    
  end

  def teardown
    @psi.delete
    @csi.delete
    @rsi.delete
    @cmsi.delete
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
    get '/en/search'
    assert_response :success
  end

  test 'search with query with loads page' do
    get '/en/search?search_term=nonexistent'
    assert_response :success
  end
  
  # test json endpoint for ajax search
  # Since "Default index to include everything and boost country index" (Sep 2020)
  # the default search spans PAs, countries and regions, with countries boosted.
  test 'search query matching a country returns it from the main search' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone', region: region)
    assert_index 2, 1

    get '/en/search-results?search_term=Manbone'
    assert_response :success
    json = JSON.parse response.body
    assert_equal 1, json['total_items']
  end

  test 'search query that returns single protected area returns success' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    pa = FactoryBot.create(:protected_area, name: "Protected Forest", countries: [country])
    assert_index 2, 2

    get '/en/search-results?search_term=forest'

    assert_response :success
    json = JSON.parse response.body
    assert_equal 1, json['total_items']
  end

  test 'search query matching a PA and a country returns both' do

    region = FactoryBot.create(:region, id: 987, name: 'Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'North Manbone land', region: region)
    pa = FactoryBot.create(:protected_area, name: "North Protected Forest", countries: [country])
    assert_index 2, 2

    get '/en/search-results?search_term=north'

    assert_response :success
    json = JSON.parse response.body
    assert_equal 2, json['total_items']
  end
end
