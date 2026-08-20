require 'test_helper'
require Rails.root.join('lib/smoke/route_walker')

class SmokeRouteWalkerTest < ActiveSupport::TestCase
  def walker(**opts)
    Smoke::RouteWalker.new(logger: StringIO.new, cms_sample: 2, **opts)
  end

  # The point of the smoke task is coverage, so coverage is the thing worth
  # testing. This fails the moment someone adds a GET route with dynamic segments
  # and no resolver, which is what stops the net from quietly shrinking over time.
  test 'every GET route is either walked or deliberately skipped' do
    w = walker
    w.build_targets

    assert_empty w.unclassified,
                 "GET routes with dynamic segments and no resolver: #{w.unclassified.uniq.inspect}. " \
                 'Add a case to RouteWalker#dynamic_targets, or a reason to SKIP_CONTROLLERS/SKIP_PATHS.'
  end

  test 'framework and admin routes are skipped with a stated reason' do
    w = walker
    w.build_targets

    skipped = w.skipped.to_h
    assert skipped.keys.any? { |l| l.start_with?('active_storage/') },
           'ActiveStorage controllers live under /rails but are not named rails/*, ' \
           'so they need their own skip rule'
    assert skipped.keys.any? { |l| l.start_with?('comfy/admin/') }
    assert(w.skipped.all? { |_label, reason| reason.present? }, 'every skip must carry a reason')
  end

  test 'no route under /admin is walked' do
    targets = walker.build_targets

    admin = targets.map(&:path).select { |p| p.start_with?('/admin') }
    # Only the deliberate auth-wall probe.
    assert_equal ['/admin'], admin
  end

  test 'targets are deduplicated by path' do
    paths = walker.build_targets.map(&:path)
    assert_equal paths.uniq, paths, 'the locale scope collapses several routes onto the same URL'
  end

  test 'the endpoints that broke during the upgrade are covered' do
    paths = walker.build_targets.map(&:path)

    # URI.encode removal in Ruby 3.0 made this 500 and killed the map overlay.
    assert paths.any? { |p| p.start_with?('/assets/tiles/') }, 'tiles endpoint must be smoked'
    # Shelled out to a phantomjs binary absent from the image.
    assert paths.any? { |p| p.end_with?('/pdf') }, 'country PDF must be smoked'
  end

  test '#static_path substitutes a locale rather than stripping it' do
    w = walker
    route = Rails.application.routes.routes.find do |r|
      r.defaults[:controller] == 'country' && r.defaults[:action] == 'show'
    end

    # Not "/country/:iso". `get '/:id'` is declared above the locale scope in
    # routes.rb and shadows every single-segment path, so a bare /search or
    # /terms resolves to protected_areas#show and 404s. Only the locale-prefixed
    # form reaches the route that was declared -- verified against production.
    assert_equal '/en/country/:iso', w.static_path(route)
  end

  test 'single-segment routes shadowed by the /:id catch-all are walked with a locale prefix' do
    paths = walker.build_targets.map(&:path)

    %w[search search-areas terms global_statistics_download].each do |slug|
      refute_includes paths, "/#{slug}",
                      "bare /#{slug} is swallowed by the /:id catch-all and would 404 spuriously"
      assert paths.any? { |p| p.start_with?("/en/#{slug}") }, "/en/#{slug} must be smoked"
    end
  end

  test 'tile targets carry the type param the controller requires' do
    tiles = walker.build_targets.map(&:path).select { |p| p.start_with?('/assets/tiles/') }

    assert_equal 3, tiles.size, 'protected_area, country and region tiles'
    assert(tiles.all? { |p| p.include?('type=') },
           'AssetsController#tiles raises 404 unless params[:type] is in TYPES')
  end

  test 'a 204 is a failure, not a pass' do
    # country#pdf is `@for_pdf = true` with no app/views/country/pdf template, so
    # Rails answered 204 No Content in 9ms and an earlier version of this walker
    # scored it "ok". An empty body from a page endpoint is a broken page.
    empty = Smoke::RouteWalker::Result.new(label: 'country#pdf', path: '/en/country/AFG/pdf', status: 204)

    refute empty.healthy?
    assert_equal 'EMPTY', empty.verdict
  end

  test 'CMS page targets are locale-prefixed' do
    # Stubbed rather than fixture-driven: the test database carries no CMS pages,
    # and the property under test is the path transformation, not the data.
    relation = mock
    relation.stubs(:pluck).with(:full_path).returns(['/about', '/news-and-stories/x'])
    Comfy::Cms::Page.stubs(:order).with(:id).returns(relation)
    relation.stubs(:limit).returns(relation)

    paths = walker.cms_page_targets.map(&:path)

    # A bare CMS slug is swallowed by the /:id catch-all and 404s.
    assert_equal ['/en/about', '/en/news-and-stories/x'], paths
  end

  test 'Result counts 2xx and 3xx as healthy, 4xx/5xx and transport errors as not' do
    ok       = Smoke::RouteWalker::Result.new(label: 'a', path: '/', status: 200)
    redirect = Smoke::RouteWalker::Result.new(label: 'b', path: '/', status: 302)
    missing  = Smoke::RouteWalker::Result.new(label: 'c', path: '/', status: 404)
    boom     = Smoke::RouteWalker::Result.new(label: 'd', path: '/', status: 500)
    refused  = Smoke::RouteWalker::Result.new(label: 'e', path: '/', status: nil,
                                              error: 'Errno::ECONNREFUSED')

    assert ok.healthy?
    assert redirect.healthy?, 'locale and CMS routes legitimately redirect'
    refute missing.healthy?
    refute boom.healthy?
    refute refused.healthy?, 'a connection error is a failure, not a skip'
    assert_equal 'ERROR', refused.verdict
  end

  test '#failed? is true when a route is unclassified even if every request passed' do
    w = walker
    w.results << Smoke::RouteWalker::Result.new(label: 'a', path: '/', status: 200)
    w.unclassified << 'some/new#route'

    assert w.failed?, 'an unclassified route must fail the run, not just warn'
  end
end
