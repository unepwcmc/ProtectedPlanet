require 'test_helper'

class S3Test < ActiveSupport::TestCase
  def setup
    Rails.application.secrets.aws_access_key_id = '123'
    Rails.application.secrets.aws_secret_access_key = 'abc'
    Rails.application.secrets.aws_downloads_bucket = 'pp-downloads-development'
    Rails.application.secrets.s3_region = 'eu-west-2'
  end

  test '#new creates an S3 connection' do
    #skip("skipping broken s3 tests")
    Aws::S3::Resource.expects(:new).with({
      :access_key_id     => '123',
      :secret_access_key => 'abc',
      :region            => 'eu-west-2'
    })

    S3.new()
  end

  test '#upload, given an object name and a file, uploads the file to S3
   with the object name' do
    object_name = 'object_name'

    file_mock = mock()
    file_mock.expects(:upload_file)

    bucket_mock = mock()
    bucket_mock.expects(:object).returns(file_mock)

    s3_mock = mock()
    s3_mock.expects(:bucket).returns(bucket_mock)
    
    Aws::S3::Resource.expects(:new).returns(s3_mock)

    client_mock = mock()
    client_mock.expects(:put_object_acl)
    Aws::S3::Client.expects(:new).returns(client_mock)

    S3.upload object_name, __FILE__
  end
end
