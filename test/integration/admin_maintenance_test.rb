require 'test_helper'

class AdminMaintenanceTest < ActionDispatch::IntegrationTest
  test 'PUT /admin/maintenance, given an authentication code, turns on
   maintenance mode so that the site is unavailable' do
    key = Rails.application.secrets.maintenance_mode_key

    put(
      '/admin/maintenance',
      params: { maintenance_mode_on: true },
      headers: { "X-Auth-Key" => key }
    )
    assert_response :success

    get '/'
    assert_response(503)

    assert_match(/Down for Maintenance/, @response.body)
    assert File.exists?(File.join(Rails.root, 'tmp', 'maintenance.yml')),
      "Expected a maintenance config file to exist when in maintenance mode"
  end

  test 'PUT /admin/maintenance mode, given a false mode status, turns
   off maintenance mode' do
    key = Rails.application.secrets.maintenance_mode_key
    seed_cms_home
    
    put(
      '/admin/maintenance',
      params: { maintenance_mode_on: true },
      headers: { "X-Auth-Key" => key }
    )
    assert_response :success

    put(
      '/admin/maintenance',
      params: { maintenance_mode_on: false },
      headers: { "X-Auth-Key" => key }
    )
    assert_response :success

    get '/en'
    assert_response :success

    assert_no_match(/Down for Maintenance/, @response.body)
    refute File.exists?(File.join(Rails.root, 'tmp', 'maintenance.yml')),
      "Expected a maintenance config file to not exist when not in
       maintenance mode"
  end

  test 'PUT /admin/maintenance returns 401 if an invalid authentication
   code is given' do
    put '/admin/maintenance', params: { maintenance_mode_on: false }
    assert_response 401
  end

  test 'PUT /admin/clear_cache, given an authentication code, clears the Rails cache' do
    cache_key = 'test_key'
    Rails.cache.write(cache_key, 'value')

    key = Rails.application.secrets.maintenance_mode_key
    put '/admin/clear_cache', params: {}, headers: {"X-Auth-Key" => key}

    assert_response :success
    assert_nil Rails.cache.read(cache_key)
  end

  def teardown
    Turnout::MaintenanceFile.default.delete
  end
end
