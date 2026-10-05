require 'test_helper'

# PPRedis pins this app to its own Redis logical database, because three
# co-located Kamal apps were sharing database 0 and Sidekiq 7 has no namespaces,
# so they raced for `queue:default` and silently ate each other's jobs.
#
# The first version of this initializer raised on a blank REDIS_URL. That broke
# the image build: assets:precompile and vite:build_all boot the whole Rails app
# with no runtime secrets present (the same reason SECRET_KEY_BASE_DUMMY exists),
# so REDIS_URL is legitimately absent there and the deploy failed at
# `rake vite:build_all` with "REDIS_URL is not set".
#
# These tests hold the line in both directions: a missing URL must not raise, and
# a present URL must still land on our own database.
class PPRedisTest < ActiveSupport::TestCase
  def setup
    reset_memo
  end

  def teardown
    reset_memo
  end

  def reset_memo
    PPRedis.instance_variable_set(:@url, nil)
  end

  def with_redis_url(value)
    AppSecrets.stubs(:redis).returns({ url: value })
    yield
  end

  test 'a blank REDIS_URL falls back instead of raising, so the image build can boot Rails' do
    with_redis_url(nil) do
      ENV.delete('REDIS_URL')

      url = nil
      assert_nothing_raised { url = PPRedis.url }

      assert_equal "#{PPRedis::FALLBACK_URL}/#{PPRedis::DEFAULT_DB}", url
      refute PPRedis.configured?, 'nothing supplied a URL, so this is the fallback'
    end
  end

  test 'a configured URL keeps its host and credentials but moves to our database' do
    with_redis_url('redis://:s3cret@redis.internal:6379/0') do
      assert_equal "redis://:s3cret@redis.internal:6379/#{PPRedis::DEFAULT_DB}", PPRedis.url
      assert PPRedis.configured?
    end
  end

  test 'REDIS_DB overrides the default database' do
    # Production runs its own Redis with nothing to collide with, so it is set to
    # REDIS_DB=0 to keep using the database its existing keys already live in.
    with_redis_url('redis://redis.internal:6379/0') do
      ENV['REDIS_DB'] = '0'
      assert_equal 'redis://redis.internal:6379/0', PPRedis.url
    ensure
      ENV.delete('REDIS_DB')
    end
  end

  test '#describe exposes host/port/db without leaking credentials' do
    with_redis_url('redis://:s3cret@redis.internal:6379/0') do
      described = PPRedis.describe

      assert_equal "redis.internal:6379/#{PPRedis::DEFAULT_DB}", described
      refute_includes described, 's3cret'
    end
  end

  test 'the Sidekiq client and server are both pointed at the same URL' do
    # Only configure_server was set before. The client fell back to Sidekiq's own
    # ENV["REDIS_URL"] default, which was harmless while both resolved to the same
    # place -- but with a pinned database, Puma would enqueue into database 0
    # while Sidekiq polled database 3 and every job would vanish.
    assert_equal Sidekiq.default_configuration.redis_pool.checkout.config.db,
                 URI.parse(PPRedis.url).path.delete('/').to_i
  end
end
