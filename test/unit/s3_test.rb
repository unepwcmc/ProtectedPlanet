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
    file_mock.expects(:write).with(Pathname.new(__FILE__), {acl: :public_read, content_length: 10})

    bucket_mock = mock()
    bucket_mock.expects(:objects).returns({object_name => file_mock})

    s3_mock = mock()
    s3_mock.expects(:buckets).returns({'pp-downloads-development' => bucket_mock})

    AWS::S3.expects(:new).returns(s3_mock)

    S3.upload object_name, __FILE__
  end

  test '#replace_all, given two prefixes, replaces all files with a prefix with
   all files from the other' do
    old_prefix, new_prefix = 'old/', 'new/'

    object_mock = mock()
    object_mock.stubs(:key).returns(old_prefix + 'test')
    object_mock.expects(:move_to).with(new_prefix + 'test', acl: :public_read)

    object_collection_mock = mock()
    object_collection_mock.expects(:delete_all)
    object_collection_mock.stubs(:each).yields(object_mock)

    objects_mock = mock()
    objects_mock.stubs(:with_prefix).returns(object_collection_mock)

    bucket_mock = mock()
    bucket_mock.stubs(:objects).returns(objects_mock)

    s3_mock = mock()
    s3_mock.expects(:buckets).returns({'pp-downloads-development' => bucket_mock})

    AWS::S3.expects(:new).returns(s3_mock)

    S3.replace_all(old_prefix, new_prefix)
  end
end
