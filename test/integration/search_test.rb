require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  test 'submitting a search query shows a list of results' do
    query = 'Killbear'
    searched_pa_name = 'The Killbear A National Park'
    non_searched_pa_name = 'Manbone Reserve'

    found_pa = FactoryGirl.create(:protected_area, name: searched_pa_name)
    FactoryGirl.create(:protected_area, name: non_searched_pa_name)

    search = Search.new query
    search.send(:results=, ProtectedArea.where(id: found_pa.id))

    Search.expects(:search).with(query).returns(search)

    visit('/search')

    fill_in 'search_input', with: query
    click_button 'Search'

    assert page.has_content?(searched_pa_name),
      'Expected PA name to be rendered'
    assert page.has_no_content?(non_searched_pa_name),
      'Expected only searched PA names to be rendered'
  end

  test 'submitting a query with more than 10 PAs paginates the results' do
    query = 'Killbear'
    results_count = 11

    results_count.times do
      FactoryGirl.create(:protected_area, name: 'An name')
    end

    search = Search.new query
    search.send(:results=, ProtectedArea.all)

    Search.expects(:search).with(query).returns(search)

    visit("/search?q=#{query}&page=2")

    assert page.has_selector?(".pagination"),
      "Expected pagination controls to exist"

    assert_equal "2", page.find('.pagination .current').text,
      "Expected last page link to exist"

    assert page.has_content?("Showing #{results_count} results for \"#{query}\""),
      "Expected results count to be shown"
  end
end
