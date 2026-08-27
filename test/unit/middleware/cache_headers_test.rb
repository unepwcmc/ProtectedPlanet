require 'test_helper'
require_relative '../../../lib/middleware/cache_headers'

# The path patterns are the whole safety argument for a long TTL, so they are
# tested directly: staging/production mount this middleware and neither boots here.
class CacheHeadersTest < ActiveSupport::TestCase
  SAFE = 'public, max-age=0, must-revalidate'.freeze
  LONG = Middleware::CacheHeaders.long_lived

  def response_for(path, status: 200, cache_control: SAFE)
    app = ->(_env) { [status, { 'cache-control' => cache_control }, []] }
    _, headers, = Middleware::CacheHeaders.new(app).call('PATH_INFO' => path)
    headers['cache-control']
  end

  def assert_policy(expected, path)
    assert_equal expected, response_for(path), path
  end

  test 'fingerprinted build output gets the long TTL' do
    ['/vite/assets/application-DfR2xQ1a.js',
     '/vite/assets/vitecss-9aB2xY7z.css',
     '/vite-dev/assets/Card-BKsJOGsd.css',
     # Sprockets, on public pages -- real 64-hex digests as precompile writes them.
     '/assets/flags/ITA-bec07637868b6019e4de0213011c9c72cdb7b935d849bb28ec2382ee62e72606.svg',
     '/assets/logos/parcc-1cc44ef250dc4e839e5ef1508845251328c1790ecc0c235fc82ef95d6f34512c.webp',
     '/assets/comfy/admin/cms-b1946ac92492d2347c6235b4d2611184.css'].each do |path|
      assert_policy LONG, path
    end
  end

  # These set their own Cache-Control and this middleware runs last on the way out,
  # so a pattern matching them would silently win. Tiles are in the list on
  # purpose: AssetsController sets the header itself, so Rack::Cache can see it.
  test 'endpoints that own their policy are never stamped' do
    ['/assets/tiles/555637',
     '/assets/tiles/ITA',
     '/sitemap.xml',
     '/sitemaps/protected-areas-1.xml',
     '/en/downloads/poll',
     '/en/downloads/1234'].each { |path| assert_policy SAFE, path }
  end

  # The first two are the dev-only trap: with assets.compile on, Sprockets answers
  # the non-digested logical path with a 200, and that url is stable, so pinning it
  # would serve a stale asset.
  test 'unhashed paths are left alone' do
    ['/assets/flags/ITA.svg',
     '/assets/logos/parcc.webp',
     '/assets/comfy/admin/cms/application.css',
     '/vite/logo.svg',
     '/vite-dev/@vite/client',
     '/vite-dev/entrypoints/application.ts',
     '/images/hero.jpg',
     '/fonts/inter.woff2',
     '/favicon.ico',
     '/manifest.json',
     '/en/country/ITA',
     '/'].each { |path| assert_policy SAFE, path }
  end

  # Sprockets is mounted at /assets wherever assets.compile is on, and a Rack mount
  # rewrites PATH_INFO in place before the response comes back. Reading env after
  # the downstream call therefore saw "/flags/ITA-<digest>.svg" and matched nothing.
  test 'a downstream app that rewrites PATH_INFO does not defeat the match' do
    mount = lambda do |env|
      env['SCRIPT_NAME'] = '/assets'
      env['PATH_INFO'] = env['PATH_INFO'].sub(%r{\A/assets}, '')

      [200, { 'cache-control' => 'public, max-age=31536000' }, []]
    end

    path = '/assets/flags/ITA-bec07637868b6019e4de0213011c9c72cdb7b935d849bb28ec2382ee62e72606.svg'
    _, headers, = Middleware::CacheHeaders.new(mount).call('PATH_INFO' => path)

    assert_equal LONG, headers['cache-control']
  end

  # A miss falls through Static to a 404; pinning it would outlive the fix.
  test 'only 200 and 304 are stamped' do
    assert_equal 'no-cache',
                 response_for('/vite/assets/gone-AAAA1111.js', status: 404, cache_control: 'no-cache')
    assert_equal LONG, response_for('/vite/assets/application-DfR2xQ1a.js', status: 304)
  end
end
