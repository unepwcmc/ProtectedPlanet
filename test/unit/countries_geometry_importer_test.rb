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

    file_mock = mock()
    file_mock.stubs(:read).returns(true)

    bucket_mock = mock()
    bucket_mock.stubs(:objects).returns({'countries_geometries_dump.tar.gz' => file_mock})

    s3_mock = mock()
    s3_mock.stubs(:buckets).returns({'ppe.datasets' => bucket_mock})

    AWS::S3.expects(:new).returns(s3_mock)

    filename = 'countries_geometries_dump.tar.gz'

    filepath = File.join(Rails.root, 'tmp', filename)
    countries_geometries = CountriesGeometryImporter.new
    countries_geometries.download_countries_geometries_to(filename, filepath)

  end

  test 'imports countries dump table' do
    filepath = File.join(Rails.root, 'tmp', 'compressed_table.tar.gz')

    CountriesGeometryImporter.expects(:system).
    with("pg_restore -c -i -U postgres -d pp_development -v #{filepath}").
    returns(true)

    response =  CountriesGeometryImporter.restore_table filepath
    assert response, "Expected restore_table to return true on success"
  end


  test 'updates countries table' do
    type = 'AIR'
    country = 'BAM'
    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE countries
        SET air_geom = the_geom
        FROM countries_geometries_temp
        WHERE type = 'AIR' AND iso_3 = 'BAM'
      """.squish).
      returns(true)

    response = CountriesGeometryImporter.update_table type, country
    assert response, "Expected update_table to return true on success"

  end

  test 'deletes old table' do
    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        DELETE FROM countries_geometries_temp
      """.squish).
      returns(true)

    response = CountriesGeometryImporter.delete_temp_table
    assert response, "Expected delete_table to return true on success"
  end

end