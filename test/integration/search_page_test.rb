# coding: utf-8
require 'test_helper'

class SearchPageTest < ActionDispatch::IntegrationTest

  def setup
    # ES and WebMock don't get along
    WebMock.disable!
    # need some data to force index/field creation but don't want it to be found in test searches
    region = FactoryGirl.create(:region, id: 999, name: 'jsdfasdf')
    country = FactoryGirl.create(:country, id: 999, iso_3: 'jsd', name: 'jsdjkjkasdhf', region: region)
    pa = FactoryGirl.create(:protected_area, name: "skdfhshdf", countries: [country], marine: false, has_parcc_info: false, is_green_list: false, has_irreplaceability_info: false)

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

  
  test 'search without query or filter redirects to home page' do
    get '/search'
    assert_redirected_to "/"
  end

  test 'search query that returns no results returns success' do
    get '/search?q=nonexistent'
    assert_response :success
    assert_select "h1", "No results found"
  end
  

  test 'search query that returns single country returns success' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    assert_index 2, 1

    get '/search?q=land'

    assert_response :success
    assert_select "h3>a", "Manbone land"
  end

  test 'search query that returns single protected area returns success' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manbone land', region: region)
    pa = FactoryGirl.create(:protected_area, name: "Protected Forest", countries: [country])
    assert_index 2, 2

    get '/search?q=forest'

    assert_response :success
    assert_select "h3>a", "Protected Forest"
  end

  test 'search query that returns PA and country returns success' do
    skip()
    region = FactoryGirl.create(:region, id: 987, name: 'Manmerica')
    country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'North Manbone land', region: region)
    pa = FactoryGirl.create(:protected_area, name: "North Protected Forest", countries: [country])
    assert_index 2, 2

    get '/search?q=north'

    assert_response :success
    assert_select "h3>a", 2
  end

  
end
