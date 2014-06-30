require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test '.commaify delimits the given number with commas' do
    assert_equal "22,123,456", commaify(22123456)
    assert_equal "22,123,456", commaify("22123456")
  end
end
