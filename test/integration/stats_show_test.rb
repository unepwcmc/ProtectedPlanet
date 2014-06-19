require 'test_helper'

class ProtectedAreaShowTest < ActionDispatch::IntegrationTest

  test 'renders the Global stats' do
    

    get '/stats'
    assert_match /stats/, @response.body
  end
end