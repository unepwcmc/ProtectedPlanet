require 'test_helper'

class StaticPagesControllerTest < ActionController::TestCase
  test "should get terms" do
    get :terms
    assert_response :success
  end

  test "should get wdpa terms" do
    get :wdpa_terms
    assert_response :success
  end
end
