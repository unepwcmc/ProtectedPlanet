require 'test_helper'

# Sidekiq::Web is mounted inside this app (config/routes.rb:9), so the only thing
# standing between a caller and the job console is the Rack::Auth::Basic wrapper
# added in config/initializers/sidekiq.rb.
#
# It was mounted bare until 2026-09-04, when a direct probe of staging returned
# 200 for GET /admin/sidekiq with no credentials while /admin/sites correctly
# returned 401. The console can retry and delete jobs -- WDPA imports, PDF
# renders, downloads -- so an unauthenticated 200 here is a real hole, and a
# regression would be invisible without this test.
class SidekiqWebAuthTest < ActionDispatch::IntegrationTest
  USERNAME = 'sidekiq-test-user'.freeze
  PASSWORD = 'sidekiq-test-password'.freeze

  # The wrapper reads ENV at request time, so the credentials can be set per test
  # rather than needing the initializer re-run.
  def with_credentials(username: USERNAME, password: PASSWORD)
    original = ENV.values_at('COMFY_ADMIN_USERNAME', 'COMFY_ADMIN_PASSWORD')
    ENV['COMFY_ADMIN_USERNAME'] = username
    ENV['COMFY_ADMIN_PASSWORD'] = password
    yield
  ensure
    ENV['COMFY_ADMIN_USERNAME'], ENV['COMFY_ADMIN_PASSWORD'] = original
  end

  def basic_auth(username, password)
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  test 'the job console rejects a request with no credentials' do
    with_credentials do
      get '/admin/sidekiq'
      assert_response :unauthorized
    end
  end

  test 'the job console rejects the wrong password' do
    with_credentials do
      get '/admin/sidekiq', headers: basic_auth(USERNAME, 'not-the-password')
      assert_response :unauthorized
    end
  end

  test 'the job console rejects the wrong username' do
    with_credentials do
      get '/admin/sidekiq', headers: basic_auth('not-the-user', PASSWORD)
      assert_response :unauthorized
    end
  end

  test 'the job console accepts the configured credentials' do
    with_credentials do
      get '/admin/sidekiq', headers: basic_auth(USERNAME, PASSWORD)
      assert_response :success
    end
  end

  # An unset secret must not reopen the door. Without the explicit blank guard a
  # nil == nil comparison would authenticate every caller sending empty
  # credentials -- which is the worst possible failure mode for this endpoint.
  test 'the job console stays closed when the credentials are not configured' do
    with_credentials(username: '', password: '') do
      get '/admin/sidekiq', headers: basic_auth('', '')
      assert_response :unauthorized
    end
  end
end
