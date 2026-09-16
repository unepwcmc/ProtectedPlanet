require 'test_helper'

# Rack::Attack guards two surfaces. The shape of each rule matters as much as the
# limit, because WCMC staff reach this through a shared office/VPN egress: a whole
# team can arrive as ONE IP, so anything counting ordinary work per-IP punishes
# exactly the people who should be using it.
#
#   * POST /downloads is throttled, generously — each unique request enqueues a
#     Sidekiq job writing a multi-GB artefact, so this is a runaway-script cap.
#   * /admin is NOT throttled. Only FAILED authentications are counted, so a team
#     editing CMS pages together is never limited however heavy the session.
#
# There is deliberately no global cap: the post-deploy hook walks 46 URLs in
# seconds from one IP, and a blanket cap low enough to matter would fail every
# deploy. The last tests pin these omissions so nobody "tightens" them later.
class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store.clear
    Rack::Attack.enabled = true
  end

  teardown { Rack::Attack.cache.store.clear }

  def post_download(ip:)
    post '/downloads',
         params: { domain: 'protected_area', format: 'csv', token: '1' },
         headers: { 'REMOTE_ADDR' => ip }
  end

  def get_admin(ip:, path: '/admin/sites', auth: nil)
    headers = { 'REMOTE_ADDR' => ip }
    headers['HTTP_AUTHORIZATION'] = auth if auth
    get path, headers: headers
  end

  test 'download creation is throttled per IP' do
    60.times { post_download(ip: '1.2.3.4') }
    refute_equal 429, response.status, 'the 60th request is still within the limit'

    post_download(ip: '1.2.3.4')
    assert_equal 429, response.status
    assert_equal '60', response.headers['Retry-After']
  end

  test 'a throttled IP does not affect a different IP' do
    61.times { post_download(ip: '1.2.3.4') }
    assert_equal 429, response.status

    post_download(ip: '5.6.7.8')
    refute_equal 429, response.status
  end

  test 'download polling is never throttled' do
    40.times do
      get '/en/downloads/poll',
          params: { domain: 'protected_area', format: 'csv', token: '1' },
          headers: { 'REMOTE_ADDR' => '4.4.4.4' }
    end

    refute_equal 429, response.status
  end

  # The smoke walk issues ~46 GETs from one IP in a few seconds.
  test 'a burst of ordinary GETs from one IP is not throttled' do
    50.times { get '/en', headers: { 'REMOTE_ADDR' => '7.7.7.7' } }

    refute_equal 429, response.status
  end

  test 'repeated failed admin logins get the IP blocked' do
    20.times { get_admin(ip: '8.8.8.8') }
    assert_equal 401, response.status, 'still merely unauthorized at the limit'

    get_admin(ip: '8.8.8.8')
    assert_equal 403, response.status, 'blocked after exceeding the failure budget'
  end

  test 'a blocked IP does not affect a different IP' do
    21.times { get_admin(ip: '8.8.8.8') }
    assert_equal 403, response.status

    get_admin(ip: '9.9.9.9')
    assert_equal 401, response.status
  end

  # The point of counting failures rather than requests: a shared VPN egress with
  # several editors working hard must never be limited.
  test 'successful admin requests are unlimited' do
    creds = ActionController::HttpAuthentication::Basic
            .encode_credentials(ENV['COMFY_ADMIN_USERNAME'], ENV['COMFY_ADMIN_PASSWORD'])

    100.times { get_admin(ip: '3.3.3.3', auth: creds) }

    refute_equal 403, response.status
    refute_equal 429, response.status
  end

  # Sidekiq's dashboard polls /admin/sidekiq/stats on a timer. Counting those 401s
  # would let an idle open dashboard ban the office.
  test 'the sidekiq dashboard poll never counts towards the ban' do
    50.times { get_admin(ip: '6.6.6.6', path: '/admin/sidekiq/stats') }

    get_admin(ip: '6.6.6.6')
    refute_equal 403, response.status
  end
end
