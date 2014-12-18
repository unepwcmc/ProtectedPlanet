require 'test_helper'

class DownloadUtilsTest < ActiveSupport::TestCase
  test '.link_to, given a name and a type, returns a link to the
   download S3 bucket for that object name' do
    download_name = 'that-download'
    type = :csv

    Rails.application.secrets.aws_downloads_bucket = 'pp-downloads-development'
    url = Rails.application.secrets.aws_s3_url

    expected_url = "#{url}/#{S3::CURRENT_PREFIX}that-download-csv.zip"
    url = Download::Utils.link_to download_name, type

    assert_equal expected_url, url
  end

  test '.make_current moves all downloads to current folder in S3' do
    S3.expects(:replace_all).with(S3::IMPORT_PREFIX, S3::CURRENT_PREFIX)
    Download::Utils.make_current
  end

  test '.key, given a domain and an identifier, returns the redis key for the given args' do
    assert_equal 'downloads:searches:123', Download::Utils.key('search', '123')
    assert_equal 'downloads:general:USA', Download::Utils.key('general', 'USA')
    assert_equal 'downloads:projects:123:all', Download::Utils.key('project', '123')
  end
end
