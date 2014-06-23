require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  test 'submitting a search query shows a list of results' do
    query = 'Killbear'
    searched_pa_name = 'The Killbear A National Park'
    non_searched_pa_name = 'Manbone Reserve'

    FactoryGirl.create(:protected_area, name: non_searched_pa_name)
    found_pa = FactoryGirl.create(:protected_area, name: searched_pa_name)

    Search.expects(:count).returns(100)
    Search.expects(:search).with(query, page: 1, limit: 10).returns([found_pa])

    visit('/search')

    fill_in 'search_input', with: query
    click_button 'Search'

    assert page.has_content?(searched_pa_name),
      'Expected PA name to be rendered'
    assert page.has_no_content?(non_searched_pa_name),
      'Expected only searched PA names to be rendered'
  end

  test 'submitting a search query with a page number shows the given
   page of results' do
    query = 'Killbear'

    searched_pa_name = 'The Killbear A National Park'
    found_pa = FactoryGirl.create(:protected_area, name: searched_pa_name)

    Search.expects(:count).with(query).returns(200)
    Search.expects(:search).with(query, page: 2, limit: 10).returns([found_pa])

    visit("/search?q=#{query}&page=2")

    assert page.has_selector?(".results-pages"),
      "Expected pagination controls to exist"
    assert_equal "20", page.find('.results-pages li:last-child a').text,
      "Expected last page link to exist"

    assert page.has_content?("Showing 200 results for \"#{query}\""),
      "Expected results count to be shown"

    assert page.has_content?(searched_pa_name),
      'Expected PA name to be rendered'
  end
end
