# coding: utf-8
require 'test_helper'

class SearchAreasTest < ActionDispatch::IntegrationTest

  def setup
    # ES and WebMock don't get along
    WebMock.disable!
    # need some data to force index/field creation but don't want it to be found in test searches
    region = FactoryBot.create(:region, id: 999, name: 'jsdfasdf')
    country = FactoryBot.create(:country, id: 999, iso_3: 'jsd', name: 'jsdjkjkasdhf', region: region)
    pa = FactoryBot.create(:protected_area, name: "skdfhshdf", countries: [country], marine: false, has_parcc_info: false, has_irreplaceability_info: false)

    @psi = fresh_search_index Search::PA_INDEX, ProtectedArea.all
    @csi = fresh_search_index Search::COUNTRY_INDEX, Country.without_geometry.all
    # Default search also queries the region + CMS indices — they must exist or queries 404.
    @rsi = fresh_search_index Search::REGION_INDEX, Region.without_geometry.all
    @cmsi = fresh_search_index Search::CMS_INDEX, Comfy::Cms::SearchablePage.all

    seed_cms
    
  end

  def teardown
    @psi&.delete
    @csi&.delete
    @rsi&.delete
    @cmsi&.delete
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

  test 'search page disables download button when initial site results are empty' do
    get '/en/search-areas?search_term=nonexistent'
    assert_response :success
    # The download button's disabled state is derived client-side from the results
    # total handed to the SearchAreasPage component. Before the Vite/Vue 3 rewrite
    # this was the Vue 2 attribute :download-disabled="downloadDisabled"; the page
    # now mounts the component with props, so assert the empty total it keys off.
    assert_includes response.body, 'turbo-mount-search-areas-page'
    assert_includes response.body, '&quot;total&quot;:0'
  end
  
  # test json endpoint for ajax search
  test 'search query that would hit country, doesnt as we dont return countries in main search' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone', region: region)
    assert_index 2, 1

    get '/en/search-areas-results?geo_type=site&search_term=Manbone'
    assert_response :success
    json = JSON.parse response.body
    assert_equal 0, json['areas']['total']
  end

  test 'search query that returns single protected area returns success' do
    region = FactoryBot.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    pa = FactoryBot.create(:protected_area, name: "Protected Forest", countries: [country])
    assert_index 2, 2

    get '/en/search-areas-results?geo_type=site&search_term=forest'

    assert_response :success
    json = JSON.parse response.body
    assert_equal 1, json['areas']['total']
  end

  test 'search query that matches PA and country only returns PA' do

    region = FactoryBot.create(:region, id: 987, name: 'Manmerica')
    country = FactoryBot.create(:country, id: 123, iso_3: 'MBN', name: 'North Manbone land', region: region)
    pa = FactoryBot.create(:protected_area, name: "North Protected Forest", countries: [country])
    assert_index 2, 2

    get '/en/search-areas-results?geo_type=site&search_term=north'

    assert_response :success
    json = JSON.parse response.body
    assert_equal 1, json['areas']['total']
  end
end
