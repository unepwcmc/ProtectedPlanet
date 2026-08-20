require 'test_helper'
require 'sidekiq/api'

# Regression cover for downloads that get stuck on "generating" forever.
#
# Three Kamal apps shared one Redis logical database on staging, and Sidekiq 7
# has no namespaces, so `queue:default` was a single physical list. A download
# job popped by wdpa-pp-data-management-portal or api-pp-authentication raised
# NameError there (the constant does not exist in those apps) and, because
# DownloadWorkers::Base sets `retry: false`, was discarded silently. Nothing ever
# wrote the result key, so it stayed at "generating" with no TTL, and
# enqueue_generation_once then refused every later request for that download.
# The UI span "Generating..." indefinitely.
#
# The DB split stops the theft; these tests cover the second half -- that a key
# whose job is gone can always recover on its own.
class DownloadRequestersStaleGenerationTest < ActiveSupport::TestCase
  class FakeRequester < Download::Requesters::Base
    def initialize(format = 'csv', identifier = '14426')
      @format = format
      @identifier = identifier
    end

    attr_reader :identifier

    def domain
      'protected_area'
    end

    # expose the protected API under test
    public :enqueue_generation_once, :stale_generation?, :job_alive?
  end

  def setup
    @requester = FakeRequester.new
    @key = @requester.send(:generation_key)
  end

  def stub_key(payload)
    $redis.stubs(:get).returns(payload.is_a?(String) ? payload : payload.to_json)
  end

  def generating(age_seconds, jid: 'abc123')
    { 'status' => 'generating',
      'jid' => jid,
      'generating_at' => (Time.now.utc - age_seconds).iso8601 }
  end

  test 'a recently started generation is left alone' do
    stub_key generating(60)
    refute @requester.stale_generation?, 'a job started a minute ago must not be treated as dead'
  end

  test 'a long-running generation with a live worker is left alone' do
    stub_key generating(6.hours, jid: 'live-jid')
    # A full-WDPA .gdb export legitimately runs for hours; age alone must never
    # be the test.
    @requester.stubs(:job_alive?).with('live-jid').returns(true)

    refute @requester.stale_generation?
  end

  test 'a long-running generation whose job has vanished is stale' do
    stub_key generating(6.hours, jid: 'dead-jid')
    @requester.stubs(:job_alive?).with('dead-jid').returns(false)

    assert @requester.stale_generation?
  end

  test 'a generating key with no timestamp is stale' do
    # Keys written before this change carry no generating_at, so there is no
    # evidence any job is alive. Recoverable beats permanently wedged.
    stub_key({ 'status' => 'generating' })
    assert @requester.stale_generation?
  end

  test 'a stale key is re-enqueued and its enqueue lock is dropped' do
    stub_key generating(6.hours, jid: 'dead-jid')
    @requester.stubs(:job_alive?).with('dead-jid').returns(false)

    lock_key = Download::Utils.enqueue_lock_key(@key)
    # The 30-minute enqueue lock would otherwise keep blocking the retry we just
    # decided to allow, so it must be cleared explicitly.
    $redis.expects(:del).with(lock_key).at_least_once
    $redis.stubs(:set).returns(true)

    assert @requester.enqueue_generation_once { 'new-jid' }
  end

  test 'a ready download is never re-enqueued' do
    stub_key({ 'status' => 'ready', 'filename' => 'WDPA_x.zip' })
    $redis.expects(:set).never

    refute @requester.enqueue_generation_once { flunk 'must not enqueue over a ready download' }
  end

  test 'job_alive? assumes alive when Sidekiq cannot be reached' do
    # Concluding "dead" on a Redis/Sidekiq blip would let every polling request
    # re-enqueue at once. GENERATING_TTL is the backstop instead.
    Sidekiq::Workers.stubs(:new).raises(Redis::CannotConnectError, 'down')
    assert @requester.job_alive?('any-jid')
  end

  test 'job_alive? is false for a blank jid' do
    refute @requester.job_alive?(nil)
    refute @requester.job_alive?('')
  end
end
