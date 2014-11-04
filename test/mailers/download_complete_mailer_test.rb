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

    assert_match(
      Regexp.new("http://localhost:3000/downloads/#{filename}\\?type=csv"),
      email.body.to_s
    )
    assert_match(
      Regexp.new("http://localhost:3000/downloads/#{filename}\\?type=kml"),
      email.body.to_s
    )
    assert_match(
      Regexp.new("http://localhost:3000/downloads/#{filename}\\?type=shp"),
      email.body.to_s
    )
  end
end
