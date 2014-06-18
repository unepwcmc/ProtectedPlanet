require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  test 'submitting a search query shows a list of results' do
    query = 'Killbear'
    searched_pa_name = 'The Killbear A National Park'
    non_searched_pa_name = 'Manbone Reserve'

    FactoryGirl.create(:protected_area, name: non_searched_pa_name)
    found_pa = FactoryGirl.create(:protected_area, name: searched_pa_name)

    Search.expects(:search).with(query).returns([found_pa])

    visit('/search')

    fill_in 'search_input', with: query
    click_button 'Search'

    assert page.has_content?(searched_pa_name),
      'Expected PA name to be rendered'
    assert page.has_no_content?(non_searched_pa_name),
      'Expected only searched PA names to be rendered'
  end
end
