require 'test_helper'

class TestCountriesGeometryImporter < ActiveSupport::TestCase
  def setup
    Rails.application.secrets.aws_access_key_id = '123'
    Rails.application.secrets.aws_secret_access_key = 'abc'
    Rails.application.secrets.aws_bucket = 'ppe.datasets'
  end

  test '#new creates an S3 connection' do
    AWS::S3.expects(:new).with({
      :access_key_id     => '123',
      :secret_access_key => 'abc'
    })

    CountriesGeometryImporter.new()
  end

  test 'downloads countries dump table' do

    bucket_mock = mock()
    bucket_mock.stubs(:objects).returns('countries_geometries_dump.tar.gz')

    s3_mock = mock()
    s3_mock.stubs(:buckets).returns({'ppe.datasets' => bucket_mock})

    AWS::S3.expects(:new).returns(s3_mock)

    filename = 'countries_geometries_dump.tar.gz'

    filepath = File.join(Rails.root, 'tmp', filename)

    CountriesGeometryImporter.download_countries_geometries_to(filename, filepath)

    File.delete filepath
  end

  test 'imports countries dump table' do
  end

  test 'updates countries table' do

  end

  test 'deletes old table' do

  end

end