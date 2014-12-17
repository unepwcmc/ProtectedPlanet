require 'test_helper'

class DownloadCompleteMailerTest < ActionMailer::TestCase
  test '#create, given a filename and a user, sends a download complete email with
   a download link' do
    filename = 'filename'
    address = "a@a.com"

    email = DownloadCompleteMailer.create(filename, address).deliver

    assert_equal ['no-reply@unep-wcmc.org'], email.from
    assert_equal [address], email.to
    assert_equal '[Protected Planet] Your download is ready', email.subject

    url = Rails.application.secrets.aws_s3_cdn

    assert_match(
      Regexp.new("#{url}/current/filename-csv.zip"),
      html_body(email)
    )
    assert_match(
      Regexp.new("#{url}/current/filename-kml.zip"),
      html_body(email)
    )
    assert_match(
      Regexp.new("#{url}/current/filename-shp.zip"),
      html_body(email)
    )
  end
end
