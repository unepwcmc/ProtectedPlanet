require 'test_helper'

class SitemapsControllerTest < ActionController::TestCase
  def setup
    # The test cache store persists between runs, and clear does not reach the
    # process-local memos.
    Rails.cache.clear
    Sitemap.reset_memos!
  end

  test '.index lists a sitemap per chunk' do
    get :index

    assert_response :success
    assert_equal 'application/xml', response.media_type
    assert_includes response.body, '<sitemapindex'

    Sitemap.chunk_names.each do |name|
      assert_includes response.body, "/sitemaps/#{name}.xml"
    end
  end

  test '.show lists every country page' do
    FactoryBot.create(:country, name: 'Belgium', iso_3: 'BEL')

    get :show, params: { name: 'countries' }

    assert_response :success
    assert_includes response.body, '<loc>http://test.host/en/country/BEL</loc>'
  end

  test '.show lists protected areas at their locale-less canonical path' do
    FactoryBot.create(:protected_area, site_id: 4242)

    get :show, params: { name: 'protected-areas-1' }

    assert_response :success
    # /:id is declared outside the locale scope, so these URLs carry no /en prefix.
    assert_includes response.body, '<loc>http://test.host/4242</loc>'
  end

  test '.show 404s an unknown chunk without rendering the error page' do
    get :show, params: { name: 'protected-areas-99999' }

    assert_response :not_found
    assert_empty response.body
  end

  test '.show 404s a malformed chunk name without touching the database' do
    get :show, params: { name: 'protected-areas-oops' }

    assert_response :not_found
    assert_empty response.body
  end

  # ~57MB of XML into a shared memcached, to save a cheap index-only scan.
  test 'protected area chunks are not written to the shared cache' do
    FactoryBot.create(:protected_area, site_id: 4242)
    label = Download::Config.current_label

    get :show, params: { name: 'protected-areas-1' }
    assert_response :success
    assert_nil Rails.cache.read("sitemap:chunk:protected-areas-1:http://test.host:#{label}")

    get :show, params: { name: 'countries' }
    assert_response :success
    assert_not_nil Rails.cache.read("sitemap:chunk:countries:http://test.host:#{label}")
  end

  test '.show advertises https when the request arrived over https' do
    FactoryBot.create(:protected_area, site_id: 4242)
    @request.env['HTTPS'] = 'on'

    get :show, params: { name: 'protected-areas-1' }

    assert_response :success
    assert_includes response.body, '<loc>https://test.host/4242</loc>'
  end

  # The branch the other tests never reach: both take an early return, one via
  # HTTPS=on and every other via Rails.env.local?.
  test '.show coerces http to https outside development and test' do
    FactoryBot.create(:protected_area, site_id: 4242)
    Rails.env.stubs(:local?).returns(false)

    get :show, params: { name: 'protected-areas-1' }

    assert_response :success
    assert_includes response.body, '<loc>https://test.host/4242</loc>'
    assert_not_includes response.body, '<loc>http://test.host/4242</loc>'
  end

  test '.warm! caches the chunk bounds and the static chunks' do
    FactoryBot.create(:protected_area, site_id: 4242)
    label = Download::Config.current_label

    assert_equal 1, Sitemap.warm!('https://example.test')

    assert_not_nil Rails.cache.read("sitemap:chunk_bounds:#{Sitemap::URLS_PER_CHUNK}:#{label}")
    assert_not_nil Rails.cache.read('sitemap:chunk_bounds:last_good')
    assert_not_nil Rails.cache.read("sitemap:chunk:pages:https://example.test:#{label}")
  end

  test '.show falls back to the last good bounds when the bounds query times out' do
    FactoryBot.create(:protected_area, site_id: 4242)
    Sitemap.warm!
    Sitemap.reset_memos!
    Rails.cache.delete("sitemap:chunk_bounds:#{Sitemap::URLS_PER_CHUNK}:#{Download::Config.current_label}")
    Sitemap.stubs(:query_chunk_bounds).raises(ActiveRecord::QueryCanceled)

    get :show, params: { name: 'protected-areas-1' }

    assert_response :success
    assert_includes response.body, '<loc>http://test.host/4242</loc>'
  end

  # Treating a timeout as "no protected areas" would cache an empty index for 12h.
  test '.index raises rather than publishing an empty index when there is nothing to fall back to' do
    Sitemap.stubs(:query_chunk_bounds).raises(ActiveRecord::QueryCanceled)

    assert_raises(ActiveRecord::QueryCanceled) { get :index }
  end

  test 'sitemaps are publicly cacheable for the generated bodies TTL' do
    get :index

    assert_includes response.headers['Cache-Control'], 'public'
    assert_includes response.headers['Cache-Control'], "max-age=#{Sitemap::CACHE_TTL.to_i}"
  end
end
