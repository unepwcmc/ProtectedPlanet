require 'test_helper'
require 'rack/mock'
require 'tmpdir'
require_relative '../../lib/middleware/cache_headers'

# Drives the real stack -- the middleware wrapping ActionDispatch::Static over real
# files -- rather than a stubbed inner app, so it covers the wiring the patterns
# depend on. Built by hand because only staging/production mount this middleware.
class CacheHeadersRequestTest < ActiveSupport::TestCase
  SAFE = 'public, max-age=0, must-revalidate'.freeze

  # Opposite casing to the middleware's on purpose: on Rack 2 that is what would
  # produce a duplicate Cache-Control header if it assigned instead of replacing.
  STATIC_HEADERS = { 'Cache-Control' => SAFE }.freeze

  FILES = [
    'vite/assets/application-DfR2xQ1a.js',
    'vite-dev/assets/Card-BKsJOGsd.css',
    'vite/logo.svg',
    'assets/cms-b1946ac92492d2347c6235b4d2611184.css',
    'images/hero.jpg',
    'fonts/inter.woff2',
    'favicon.ico'
  ].freeze

  def setup
    @root = Dir.mktmpdir('cache-headers')

    FILES.each do |path|
      full = File.join(@root, path)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, "contents of #{path}")
    end

    root = @root
    @app = Rack::Builder.new do
      use Middleware::CacheHeaders
      use ActionDispatch::Static, root, headers: STATIC_HEADERS
      # Stands in for Rails routing: what /assets/tiles/:id reaches.
      run ->(env) {
        if env['PATH_INFO'].start_with?('/assets/tiles/')
          [200, { 'Content-Type' => 'image/png',
                  'Cache-Control' => Middleware::CacheHeaders.long_lived }, ['PNG']]
        else
          [404, { 'Content-Type' => 'text/html' }, ['fell through to routing']]
        end
      }
    end.to_app
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def get(path, headers = {})
    Rack::MockRequest.new(@app).get(path, headers)
  end

  def cache_control_values(response)
    response.headers.select { |name, _| name.to_s.downcase == 'cache-control' }.values
  end

  def assert_single_cache_control(expected, response)
    values = cache_control_values(response)

    assert_equal 1, values.size, "expected one Cache-Control header, got #{values.inspect}"
    assert_equal expected, values.first
  end

  test 'fingerprinted output is served with the long TTL' do
    ['/vite/assets/application-DfR2xQ1a.js',
     '/vite-dev/assets/Card-BKsJOGsd.css',
     '/assets/cms-b1946ac92492d2347c6235b4d2611184.css'].each do |path|
      response = get(path)

      assert_equal 200, response.status, path
      assert_single_cache_control Middleware::CacheHeaders.long_lived, response
    end
  end

  # A controller response, not a file. The middleware sits above Static so it sees
  # these too -- and must leave this one exactly as the controller set it.
  test 'a controller response under assets tiles is left to the controller' do
    response = get('/assets/tiles/555637?type=protected_area&version=1')

    assert_equal 200, response.status
    assert_equal 'image/png', response.headers['Content-Type']
    # Exactly one header, unchanged: guards both against a tiles pattern being
    # added here (which would override the controller) and against the Rack 2
    # casing bug duplicating it.
    assert_single_cache_control Middleware::CacheHeaders.long_lived, response
  end

  test 'stable urls keep the revalidating policy' do
    ['/images/hero.jpg', '/fonts/inter.woff2', '/favicon.ico', '/vite/logo.svg'].each do |path|
      response = get(path)

      assert_equal 200, response.status, path
      assert_single_cache_control SAFE, response
    end
  end

  # What makes must-revalidate cheap: the browser asks, and gets no body back.
  test 'a stable url revalidates to a 304 with no body' do
    first = get('/images/hero.jpg')
    last_modified = first.headers['Last-Modified']

    assert last_modified.present?, 'Rack::Files should set Last-Modified'

    second = get('/images/hero.jpg', 'HTTP_IF_MODIFIED_SINCE' => last_modified)

    assert_equal 304, second.status
    assert_empty second.body
  end

  # Rack::Files, not Rack::ETag, serves these -- Static short-circuits long before
  # it. Last-Modified is the only validator, and the 304 above proves it suffices.
  test 'static files carry Last-Modified and no ETag' do
    response = get('/images/hero.jpg')

    assert response.headers['Last-Modified'].present?
    assert_nil response.headers['ETag']
  end

  test 'a fallthrough 404 on a hashed path is not pinned' do
    response = get('/vite/assets/deleted-by-the-last-build-AAAA1111.js')

    assert_equal 404, response.status
    assert_empty cache_control_values(response)
  end
end
