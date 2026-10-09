require 'test_helper'

# Guards the decision, not an implementation detail: no public page may ask a shared
# cache to hold its HTML.
#
# Page caching is what made a CMS edit invisible until the next deploy -- nothing
# invalidated the stored copy -- and what served one visitor's csrf_meta_tags token to
# the next. It is cheap to re-add by habit (`expires_in ..., public: true`, or an
# `after_action :enable_caching` copied from a sibling controller), and the symptom
# shows up days later on a deployed site, never in a test run. So it is asserted here.
#
# The expensive work is cached instead, behind Rails.cache.fetch -- see
# ApplicationController and docs/caching.md.
class NoSharedHtmlCacheTest < ActionDispatch::IntegrationTest
  # The shared-cache directives. `public` lets any cache between us and the browser
  # keep the body; s-maxage tells it for how long. Browser-private freshness
  # (`max-age`, `must-revalidate`) is fine and not checked.
  SHARED_DIRECTIVES = %w[public s-maxage].freeze

  def setup
    seed_cms_home
    seed_global_statistics
  end

  test 'the home page does not permit shared caching of its HTML' do
    get '/en'

    assert_response :success
    assert_not_shared_cacheable
  end

  test 'sitemaps remain the one deliberate exception' do
    get '/sitemap.xml'

    assert_response :success
    assert_includes directives, 'public',
      'SitemapsController#cache_for_sitemap_ttl is meant to stay shared-cacheable'
  end

  # Catches the copy-paste case the integration tests above cannot: a controller that
  # re-grows the after_action without anyone adding a request test for it.
  test 'no controller declares a page-caching after_action' do
    offenders = Dir[Rails.root.join('app/controllers/**/*.rb')].select do |path|
      File.read(path).match?(/after_action\s+:enable_caching/)
    end

    assert_empty offenders.map { |path| Pathname.new(path).relative_path_from(Rails.root).to_s },
      'page caching was re-added — see the note in ApplicationController'
  end

  private

  def directives
    response.headers['Cache-Control'].to_s.split(',').map { |d| d.strip.split('=').first }
  end

  def assert_not_shared_cacheable
    present = directives & SHARED_DIRECTIVES

    assert_empty present,
      "#{request.path} sent shared-cache directives #{present.inspect} " \
      "(Cache-Control: #{response.headers['Cache-Control']})"
  end
end
