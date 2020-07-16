require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "should get index" do
    seed_cms_home
    
    get :index
    assert_response :success
  end
end
