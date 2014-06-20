require 'test_helper'

class S3Test < ActiveSupport::TestCase
  def setup
    Rails.application.secrets.aws_access_key_id = '123'
    Rails.application.secrets.aws_secret_access_key = 'abc'
    Rails.application.secrets.aws_downloads_bucket = 'pp-downloads-development'
  end

  test '#new creates an S3 connection' do
    AWS::S3.expects(:new).with({
      :access_key_id     => '123',
      :secret_access_key => 'abc'
    })

    S3.new()
  end

  test '#upload, given an object name and a file, uploads the file to S3
   with the object name' do
    object_name = 'object_name'

    File.expects(:size).returns(10)

    file_mock = mock()
    file_mock.expects(:write).with(Pathname.new(__FILE__), {content_length: 10})

    bucket_mock = mock()
    bucket_mock.expects(:objects).returns({object_name => file_mock})

    s3_mock = mock()
    s3_mock.expects(:buckets).returns({'pp-downloads-development' => bucket_mock})

    AWS::S3.expects(:new).returns(s3_mock)

    S3.upload object_name, __FILE__
  end
end
