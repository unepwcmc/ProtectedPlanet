require 'test_helper'

# ApplicationController#safe_referrer_path exists because two rescue handlers in
# ApplicationController#record_invalid_error redirect back to `request.referrer`,
# which is a client-supplied header. Rails rejects two shapes of it and both turn
# the handler into a 500 instead of the redirect it intends:
#
#   * an off-host referrer raises UnsafeRedirectError
#     (action_on_open_redirect = :raise, on since load_defaults 7.0)
#   * a referrer not rooted at "/" raises PathRelativeRedirectError
#     (action_on_path_relative_redirect = :raise, on since load_defaults 8.1)
#
# The inputs below are the ones nobody sends by accident, which is exactly why
# they need pinning: a regression here is invisible until someone crafts a Referer.
class SafeReferrerPathTest < ActiveSupport::TestCase
  HOST = 'test.host'.freeze

  # Any ApplicationController subclass inherits the method; HomeController is the
  # cheapest one to instantiate. The controller is built by hand rather than
  # driven through a request because the method is a pure function of the Referer
  # header, and reaching it for real would mean provoking a StatementInvalid.
  def build_controller(referrer)
    controller = HomeController.new
    env = { 'HTTP_HOST' => HOST }
    env['HTTP_REFERER'] = referrer unless referrer.nil?
    controller.set_request!(ActionDispatch::TestRequest.create(env))
    controller
  end

  def safe_path(referrer)
    build_controller(referrer).send(:safe_referrer_path)
  end

  # The fallback is the controller's own root_path, which is locale-scoped ("/en"),
  # not the bare "/" of Rails.application.routes.url_helpers. Ask the controller
  # for it rather than hardcoding, so a change to the locale scope moves the
  # expectation with it -- and derive it independently of the method under test.
  def root
    build_controller(nil).send(:root_path)
  end

  test 'a same-origin referrer keeps its path' do
    assert_equal '/countries/1', safe_path("https://#{HOST}/countries/1")
  end

  # The CMS "fields cannot be empty" flow depends on this: dropping the query
  # would return the editor to the wrong place.
  test 'a same-origin referrer keeps its query string' do
    assert_equal '/countries/1?tab=stats', safe_path("https://#{HOST}/countries/1?tab=stats")
  end

  test 'a bare same-origin path is returned unchanged' do
    assert_equal '/countries/1', safe_path('/countries/1')
  end

  test 'an off-host referrer falls back to the homepage' do
    assert_equal root, safe_path('https://evil.example/pwned')
  end

  # "//evil.example/x" is protocol-relative: it has no scheme but IS off-host, and
  # a browser follows it off-site. It must not survive as a path.
  test 'a protocol-relative referrer falls back to the homepage' do
    assert_equal root, safe_path('//evil.example/pwned')
  end

  test 'a path-relative referrer falls back to the homepage' do
    assert_equal root, safe_path('foo/bar')
  end

  test 'a malformed referrer falls back to the homepage instead of raising' do
    assert_equal root, safe_path('http://[bad')
  end

  test 'a missing referrer falls back to the homepage' do
    assert_equal root, safe_path(nil)
  end

  test 'an empty referrer falls back to the homepage' do
    assert_equal root, safe_path('')
  end

  # The point of the method: whatever it returns must be something redirect_to
  # accepts under the 8.1 defaults, so no input can turn the rescue into a 500.
  test 'every result is a rooted path redirect_to will accept' do
    [
      nil, '', 'foo/bar', '//evil.example/pwned', 'http://[bad',
      'https://evil.example/pwned', "https://#{HOST}/countries/1?tab=stats"
    ].each do |referrer|
      result = safe_path(referrer)
      assert result.start_with?('/'), "#{referrer.inspect} produced #{result.inspect}"
      refute result.start_with?('//'), "#{referrer.inspect} produced #{result.inspect}"
    end
  end
end
