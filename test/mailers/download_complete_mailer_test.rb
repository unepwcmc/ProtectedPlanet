require 'test_helper'

class DownloadCompleteMailerTest < ActionMailer::TestCase
  test '#create, given a filename and a user, sends a download complete email with
   a download link' do
    filename = 'filename'
    address = "a@a.com"

    email = DownloadCompleteMailer.create(filename, address).deliver_now

    assert_equal ['no-reply@unep-wcmc.org'], email.from
    assert_equal [address], email.to
    assert_equal '[Protected Planet] Your download is ready', email.subject

    url = Rails.application.secrets.aws_s3_url

    # A download is generated for one requested format and the zip is named after
    # the download, so the email links to that single file.
    assert_match(
      Regexp.new("#{url}/current/filename.zip"),
      html_body(email)
    )
  end
end
