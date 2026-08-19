require 'test_helper'

class DownloadUtilsTest < ActiveSupport::TestCase
  test '.link_to, given a name and a type, returns a link to the
   download S3 bucket for that object name' do
    download_name = 'that-download'

    AppSecrets.aws_downloads_bucket = 'pp-downloads-development'
    url = AppSecrets.aws_s3_url

    # The zip is named after the download only; the format is no longer suffixed.
    expected_url = "#{url}/#{S3::CURRENT_PREFIX}that-download.zip"
    url = Download::Utils.link_to download_name

    assert_equal expected_url, url
  end

  test '.clear_downloads deletes all current downloads from folder in S3' do
    S3.expects(:delete_all).with(S3::CURRENT_PREFIX)
    Download::Utils.clear_downloads
  end

  test '.key, given a domain and an identifier, returns the redis key for the given args' do
    # The redis key now includes the download format.
    assert_equal 'downloads:searches:csv:123', Download::Utils.key('search', '123', 'csv')
    assert_equal 'downloads:general:csv:USA', Download::Utils.key('general', 'USA', 'csv')
    assert_equal 'downloads:projects:csv:123:all', Download::Utils.key('project', '123', 'csv')
  end

  # These keys were previously written with no expiry at all (observed ttl=-1 on
  # staging). The shared Redis runs `--maxmemory 2gb --maxmemory-policy
  # noeviction`, so an ever-growing keyspace eventually makes Redis refuse writes
  # for every app on the host, not just this one.
  test '.write always sets a TTL' do
    $redis.expects(:set).with(
      'downloads:protected_area:csv:1',
      regexp_matches(/generating/),
      has_entry(:ex, Download::Utils::GENERATING_TTL.to_i)
    )
    Download::Utils.write('downloads:protected_area:csv:1', { 'status' => 'generating' })
  end

  test '.write gives ready downloads the long TTL and failures the short one' do
    $redis.expects(:set).with(anything, anything, has_entry(:ex, Download::Utils::READY_TTL.to_i))
    Download::Utils.write('k', { 'status' => 'ready' })

    $redis.expects(:set).with(anything, anything, has_entry(:ex, Download::Utils::FAILED_TTL.to_i))
    Download::Utils.write('k', { 'status' => 'failed' })
  end

  test '.write accepts an already-encoded JSON string' do
    # DownloadWorkers::Base#while_generating hands back whatever the generator
    # returned, which is a JSON string rather than a Hash.
    $redis.expects(:set).with('k', '{"status":"ready"}', has_entry(:ex, Download::Utils::READY_TTL.to_i))
    Download::Utils.write('k', '{"status":"ready"}')
  end
end
