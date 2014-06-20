require 'test_helper'

class StatsShowTest < ActionDispatch::IntegrationTest

  test 'renders global stats' do
    
    get '/stats/global'
    assert page.has_content?, @response.body
  end

  test 'renders regional stats' do
    region_1 = FactoryGirl.create(:region, name: 'Americasia', iso: 'AMA')
    get '/stats/regional/AMA'
    assert page.has_content?, @response.body
  end

  test 'renders country stats' do
    region_1 = FactoryGirl.create(:region, name: 'Orange Emirate', iso: 'PUM')
    get '/stats/country/PUM'
    assert page.has_content?, @response.body
  end

end