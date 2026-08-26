require 'test_helper'

# The warm sits behind a `rescue StandardError` in Cleanup, so a missing constant
# would log a warning and let the release report success.
class SitemapReleaseRefreshTest < ActionDispatch::IntegrationTest
  class FakeLog
    attr_reader :events

    def initialize = @events = []

    def event(name, payload: {}, phase: nil)
      @events << [name.to_s, payload]
    end
  end

  def setup
    Rails.cache.clear
    Sitemap.reset_memos!
    @log = FakeLog.new

    # The other steps talk to Postgres maintenance, Elasticsearch and S3.
    Wdpa::Portal::Services::Core::TableCleanupService.stubs(:cleanup_after_swap)
    Search::Index.stubs(:delete)
    Search::Index.stubs(:create)
    Download.stubs(:clear_downloads)
  end

  def teardown
    Rails.cache.clear
    Sitemap.reset_memos!
  end

  test 'post_swap! warms the sitemap after clearing the cache' do
    FactoryBot.create(:protected_area, site_id: 4242)

    PortalRelease::Cleanup.post_swap!(@log)

    names = @log.events.map(&:first)
    assert_includes names, 'sitemap_warmed'
    assert_not_includes names, 'sitemap_warm_failed'
    assert_includes names, 'post_swap_cleanup_done'

    warmed = @log.events.find { |name, _| name == 'sitemap_warmed' }.last
    assert_equal 1, warmed[:protected_area_chunks]

    assert_not_nil Rails.cache.read(
      "sitemap:chunk_bounds:#{Sitemap::URLS_PER_CHUNK}:#{Download::Config.current_label}"
    )
  end

  test 'a failing warm does not fail the release' do
    Sitemap.stubs(:warm!).raises(StandardError, 'memcached unreachable')

    assert_nothing_raised { PortalRelease::Cleanup.post_swap!(@log) }

    names = @log.events.map(&:first)
    assert_includes names, 'sitemap_warm_failed'
    assert_includes names, 'post_swap_cleanup_done'
  end

  test 'a release publishes protected areas that did not exist before it' do
    FactoryBot.create(:protected_area, site_id: 4242)
    Release.create!(label: 'Aug2026', state: 'succeeded').make_current!
    Sitemap.warm!('https://example.test')

    get '/sitemaps/protected-areas-1.xml'
    assert_response :success
    assert_includes response.body, '<loc>http://www.example.com/4242</loc>'
    assert_not_includes response.body, '/5353'

    # The release imports a new area and moves the label on.
    FactoryBot.create(:protected_area, site_id: 5353)
    Release.create!(label: 'Sep2026', state: 'succeeded').make_current!
    PortalRelease::Cleanup.post_swap!(@log)

    Sitemap.reset_memos! # production waits out MEMO_TTL; a test cannot

    get '/sitemaps/protected-areas-1.xml'
    assert_response :success
    assert_includes response.body, '<loc>http://www.example.com/5353</loc>'
    assert_includes response.body, '<loc>http://www.example.com/4242</loc>'
  end

  test 'post_swap! carries the last good bounds across its cache clear' do
    FactoryBot.create(:protected_area, site_id: 4242)
    Sitemap.warm!('https://example.test')
    before = Rails.cache.read("sitemap:#{Sitemap::LAST_GOOD_BOUNDS_KEY}")
    assert_not_nil before, 'warm! should have recorded the bounds it computed'

    PortalRelease::Cleanup.post_swap!(@log)

    assert_equal before, Rails.cache.read("sitemap:#{Sitemap::LAST_GOOD_BOUNDS_KEY}")
  end

  test 'post_swap! still clears the cache when preserving the fallback fails' do
    Rails.cache.write('sitemap:chunk:countries:https://example.test:x', '<STALE/>')
    Sitemap.stubs(:preserving_last_good_bounds).raises(StandardError, 'memcached hiccup')

    PortalRelease::Cleanup.post_swap!(@log)

    assert_nil Rails.cache.read('sitemap:chunk:countries:https://example.test:x')
    assert_includes @log.events.map(&:first), 'post_swap_cleanup_done'
  end

  test 'the cleared cache alone refreshes a chunk when the label is unchanged' do
    # Not in the test database's country seed.
    new_iso = 'ZZZ'
    assert_nil Country.find_by(iso_3: new_iso)

    Sitemap.warm!('https://example.test')
    get '/sitemaps/countries.xml'
    assert_not_includes response.body, "/en/country/#{new_iso}"

    FactoryBot.create(:country, name: 'Testlandia', iso_3: new_iso)
    get '/sitemaps/countries.xml'
    assert_not_includes response.body, "/en/country/#{new_iso}",
      'the pre-release body is cached, so a bare insert must not show up on its own'

    PortalRelease::Cleanup.post_swap!(@log)
    Sitemap.reset_memos!

    get '/sitemaps/countries.xml'
    assert_includes response.body, "/en/country/#{new_iso}"
  end
end
