require 'test_helper'

class HomeHelperTest < ActionView::TestCase
  test '.nav_main_background_class returns "home-nav-main" if in the
   `home` controller' do
    assert_equal 'home-nav-main', nav_main_background_class('home')
  end
end
