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
    params = {q: 'boneman', country: 123}
    expected_link = '<a href="/search?q=boneman">Clear Filters</a>'
    assert_equal expected_link, clear_filters_link(params)
  end
end
