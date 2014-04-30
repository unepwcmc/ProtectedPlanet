require 'test_helper'

class TestWdpaGetter < ActiveSupport::TestCase
  def setup
    Rails.application.secrets.aws_access_key_id = '123'
    Rails.application.secrets.aws_secret_access_key = 'abc'
    Rails.application.secrets.aws_bucket = 'wdpa'
  end

  test '#new creates an S3 connection' do
    AWS::S3.expects(:new).with({
      :access_key_id     => '123',
      :secret_access_key => 'abc'
    })

    WdpaGetter.new()
  end

  test '.save_current_wdpa_to retrieves the latest WDPA from S3, and saves it to the
   given filename' do
    latest_file_mock = mock()
    latest_file_mock.stubs(:last_modified).returns(2.days.ago)
    latest_file_mock.expects(:read)

    oldest_file_mock = mock()
    oldest_file_mock.stubs(:last_modified).returns(10.days.ago)
    oldest_file_mock.stubs(:read).raises(Exception, "Expected the oldest file to not be downloaded")

    bucket_mock = mock()
    bucket_mock.stubs(:objects).returns([
      latest_file_mock,
      oldest_file_mock
    ])

    s3_mock = mock()
    s3_mock.stubs(:buckets).returns({'wdpa' => bucket_mock})

    AWS::S3.expects(:new).returns(s3_mock)

    filename = 'hey_this_is_a_filename.zip'

    File.expects(:open).
      with(filename, 'w').
      yields()

    wdpa_getter = WdpaGetter.new()
    wdpa_getter.save_current_wdpa_to(filename: filename)
  end
end
