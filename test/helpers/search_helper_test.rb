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

  test '#link_to_search, given params and a filter, returns a link to
   the current search with the new filter' do
    params = {
      query: 'test',
      type: 'country'
    }

    model = FactoryGirl.create(:country, name: 'Manbone', id: 123)

    facet = {
      model: model,
      count: 4
    }

    expected_link = "<a href=\"/search?country=123&amp;query=test&amp;type=country\">Manbone (4)</a>"
    link = facet_link facet, params

    assert_equal expected_link, link
  end
end
