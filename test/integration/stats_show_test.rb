require 'test_helper'

class StatsShowTest < ActionDispatch::IntegrationTest

  test 'renders the Global stats' do
    
    get '/stats/global'
    assert page.has_content?, @response.body
  end




end