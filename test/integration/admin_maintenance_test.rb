require 'test_helper'

class AdminMaintenanceTest < ActionDispatch::IntegrationTest
  test 'PUT /admin/maintenance, given an authentication code, turns on
   maintenance mode so that the site is unavailable' do
    key = Rails.application.secrets.maintenance_mode_key

    put(
      '/admin/maintenance',
      {maintenance_mode_on: true},
      {"X-Auth-Key" => key}
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

    put(
      '/admin/maintenance',
      {maintenance_mode_on: true},
      {"X-Auth-Key" => key}
    )
    assert_response :success

    put(
      '/admin/maintenance',
      {maintenance_mode_on: false},
      {"X-Auth-Key" => key}
    )
    assert_response :success

    get '/'
    assert_response :success

    assert_no_match(/Down for Maintenance/, @response.body)
    refute File.exists?(File.join(Rails.root, 'tmp', 'maintenance.yml')),
      "Expected a maintenance config file to not exist when not in
       maintenance mode"
  end

  test 'PUT /admin/maintenance returns 401 if an invalid authentication
   code is given' do
    put '/admin/maintenance', maintenance_mode_on: false
    assert_response 401
  end

  def teardown
    Turnout::MaintenanceFile.default.delete
  end
end
