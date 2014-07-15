require 'test_helper'

class StaticPagesTest < ActionDispatch::IntegrationTest
  test '/terms renders the Terms and Conditions' do
    get '/terms'

    assert_response :success
  end
end
