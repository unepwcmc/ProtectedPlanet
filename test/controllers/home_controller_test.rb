require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "should get index" do
    seed_cms_home
    seed_global_statistics

    get :index
    assert_response :success
  end
end
