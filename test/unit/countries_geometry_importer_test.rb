require 'test_helper'

class TestCountriesGeometryImporter < ActiveSupport::TestCase
  test '#import downloads the geometries from S4, imports to postgres
   and updates each Country with the matching geometries' do
    skip("skipping broken S3 tests")
    bucket = Rails.application.secrets.aws_datasets_bucket

    filename = 'countries_geometries_dump.tar.gz'
    path = Rails.root.join('tmp', filename).to_s
    file_mock = mock()
    file_mock.stubs(:read).returns("geometries contents")
    bucket_mock = mock()
    bucket_mock.stubs(:objects).returns({filename => file_mock})
    s3_mock = mock()
    s3_mock.stubs(:buckets).returns({bucket => bucket_mock})
    AWS::S3.expects(:new).returns(s3_mock)

    file_write_mock = mock()
    file_write_mock.expects(:write).with("geometries contents")
    File.expects(:open).
      with(path, 'w:ASCII-8BIT').
      yields(file_write_mock).
      returns(file_write_mock)

    db_config = {
      host: 'localhost',
      database: 'database',
      username: 'username',
      password: 'password'
    }
    ActiveRecord::Base.stubs(:connection_config).returns(db_config)

    CountriesGeometryImporter.any_instance.expects(:system).
      with("PGPASSWORD=password pg_restore -c -i -U username -h localhost -d database -v #{path}").
      returns(true)

    FactoryGirl.create(:country, iso_3: 'GBR')
    FactoryGirl.create(:country, iso_3: 'USA')
    ActiveRecord::Base.connection.expects(:execute).times(6).returns(true)

    ActiveRecord::Base.connection.
      expects(:execute).
      with("DELETE FROM countries_geometries_temp").
      returns(true)

    File.expects(:delete).with(path).returns(true)

    assert CountriesGeometryImporter.import(),
      "Expected countries geometry importer to return true on success"
  end
end
