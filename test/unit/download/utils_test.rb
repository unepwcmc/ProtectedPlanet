require 'test_helper'

class DownloadUtilsTest < ActiveSupport::TestCase
  test '.link_to, given a name and a type, returns a link to the
   download S3 bucket for that object name' do
    download_name = 'that-download'
    type = :csv

    Rails.application.secrets.aws_downloads_bucket = 'pp-downloads-development'

    expected_url = "https://pp-downloads-development.s3.amazonaws.com/#{Download::CURRENT_PREFIX}that-download-csv.zip"
    url = Download.link_to download_name, type

    assert_equal expected_url, url
  end

  test '.make_current moves all downloads to current folder in S3' do
    S3.expects(:replace_all).with(Download::IMPORT_PREFIX, Download::CURRENT_PREFIX)
    Download.make_current
  end
end
