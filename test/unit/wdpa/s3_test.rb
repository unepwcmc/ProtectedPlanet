require 'test_helper'

class TestWdpaS3Downloader < ActiveSupport::TestCase
  def setup
    Rails.application.secrets.aws_access_key_id = '123'
    Rails.application.secrets.aws_secret_access_key = 'abc'
    Rails.application.secrets.aws_bucket = 'wdpa'
    Rails.application.secrets.s3_region = 'eu-west-2'

    @bucket_mock = mock()
    @s3_mock = mock()
    @s3_mock.stubs(:bucket).returns(@bucket_mock)
  end

  test '#new creates an S3 connection' do
    Aws::S3::Resource.expects(:new).with({
      :access_key_id     => '123',
      :secret_access_key => 'abc',
      :region            => 'eu-west-2'
    })

    Wdpa::S3.new()
  end

  test '.download_latest_wdpa_to handles encoding correctly' do
    filename = File.join(Rails.root, 'tmp', 'hey_this_is_a_filename.zip')
    file_contents = "\x9B".force_encoding(Encoding::ASCII_8BIT)

    latest_file_mock = mock()
    latest_file_mock.stubs(:object).returns(latest_file_mock)
    latest_file_mock.stubs(:last_modified).returns(2.days.ago)
    latest_file_mock.expects(:get).returns(file_contents)

    @bucket_mock.stubs(:objects).returns([latest_file_mock])
    Aws::S3::Resource.stubs(:new).returns(@s3_mock)

    Wdpa::S3.download_latest_wdpa_to filename
  end

  test '.download_latest_wdpa_to retrieves the latest WDPA from S3, and saves it to the
   given filename' do
    filename = 'hey_this_is_a_filename.zip'
    latest_file_mock = mock()
    latest_file_mock.stubs(:object).returns(latest_file_mock)
    latest_file_mock.stubs(:last_modified).returns(2.days.ago)
    latest_file_mock.expects(:get).returns("")

    oldest_file_mock = mock()
    oldest_file_mock.stubs(:last_modified).returns(10.days.ago)
    oldest_file_mock.stubs(:read).raises(Exception, "Expected the oldest file to not be downloaded")

    @bucket_mock.stubs(:objects).returns([
      latest_file_mock,
      oldest_file_mock
    ])

    Aws::S3::Resource.stubs(:new).returns(@s3_mock)

    Wdpa::S3.download_latest_wdpa_to filename
  end

  test '.new_wdpa? compares the current wdpa last modified time with the given
   argument' do
    older_time = Time.new(2010)
    recent_time = Time.new(2014)

    file_mock = mock()
    file_mock.expects(:last_modified).returns(recent_time)
    Wdpa::S3.any_instance.expects(:current_wdpa).returns(file_mock)

    assert Wdpa::S3.new_wdpa?(older_time),
      'Expected new_wdpa? to return true when given a time older than the current_wdpa'
  end

  test '#current_site_identifier returns a part of the WDPA filename' do
    file_mock = mock()
    file_mock.expects(:key).returns('WDPA_Apr2015_Public.zip')
    Wdpa::S3.any_instance.expects(:current_wdpa).returns(file_mock)

    assert_equal 'Apr2015', Wdpa::S3.current_site_identifier
  end

  test '#current_site_identifier returns Month+Year independently from the length of the months name' do
    file_mock = mock()
    file_mock.expects(:key).returns('WDPA_June2015_Public.zip')
    Wdpa::S3.any_instance.expects(:current_wdpa).returns(file_mock)

    assert_equal 'June2015', Wdpa::S3.current_site_identifier
  end
end
