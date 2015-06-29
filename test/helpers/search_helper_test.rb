require 'test_helper'

class SearchHelperTest < ActionView::TestCase
  test '#type_li_tag, given a type and the selected type, returns an li
   tag with a selected class if the given type matches selected type' do
    selected_class = type_li_tag('country', 'country') { "inner text" }
    assert_equal '<li class="selected">inner text</li>', selected_class
  end

  test '#type_li_tag, given a type and the selected type, returns an li
   tag without a selected class if the given type does not match
   selected type' do
    selected_class = type_li_tag('protected_area', 'country') { "inner text" }
    assert_equal '<li class="">inner text</li>', selected_class
  end

  test '#clear_filters_link, given params, returns an <a> tag to remove
   the current search filters' do
    params = {q: 'boneman', country: 123, action: 'yo', controller: 'mama'}
    expected_link = '<a href="/search?q=boneman">Clear Filters</a>'
    assert_equal expected_link, clear_filters_link(params)
  end

  test '#clear_filters_link, given params with a main filter, returns a <a> tag to the main filter' do
    params = {region: 234, country: 123, main: 'region', action: 'yo', controller: 'mama'}
    expected_link = '<a href="/search?main=region&amp;region=234">Clear Filters</a>'
    assert_equal expected_link, clear_filters_link(params)
  end

  test '#clear_filters_link, given params, returns nothing if there are
   no filters' do
    params = {q: 'boneman', action: 'yo', controller: 'mama'}
    assert_equal '', clear_filters_link(params)
  end

  test '#search_title, given the params with a query, returns the search title' do
    params = {q: 'manbone', has_parcc_info: 'true'}
    assert_equal %{Search results for <strong>"manbone"</strong>}, search_title(params)
  end

  test '#search_title, given params with no query, returns the search title' do
    params = {'has_parcc_info' => true, 'main' => 'has_parcc_info'}
    assert_equal %{Protected Areas with Vulnerability Assessment}, search_title(params)
  end

  test '#search_title, given params with a model field, returns the search title' do
    country = FactoryGirl.create(:country)

    params = {'country' => country.id, 'main' => 'country'}
    assert_equal "Protected Areas in #{country.name}", search_title(params)
  end

  test '#search_title, given params with a model that doesnt exist, returns the default search title' do
    params = {'country' => 999, 'main' => 'country'}
    assert_equal "Protected Areas", search_title(params)
  end

  test '#search_title, given params without a main param, returns the default search title' do
    params = {'country' => 123, 'has_parcc_info' => true}
    assert_equal 'Protected Areas', search_title(params)
  end
end
