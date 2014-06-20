require 'test_helper'

class StatsControllerTest < ActionController::TestCase
  # test "the truth" do
  #   assert true
  # end
  test '.index returns a 200 HTTP code' do
    get :index

    assert_response :success
  end
end
