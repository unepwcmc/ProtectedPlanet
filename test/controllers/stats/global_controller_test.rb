require 'test_helper'

class Stats::GlobalControllerTest < ActionController::TestCase
  test '.index returns a 200 HTTP code' do
    get :index
    assert_response :success
  end
end
