require 'test_helper'

class TestCountriesGeometryImporter < ActiveSupport::TestCase
  def setup
    Rails.application.secrets.aws_access_key_id = '123'
    Rails.application.secrets.aws_secret_access_key = 'abc'
    Rails.application.secrets.aws_bucket = 'ppe.datasets'
    @filename = 'countries_geometries_dump.tar.gz'
    @filepath = File.join(Rails.root, 'tmp', 'compressed_table.tar.gz')
  end

  test '#new creates an S3 connection' do
    AWS::S3.expects(:new).with({
      :access_key_id     => '123',
      :secret_access_key => 'abc'
    })

    CountriesGeometryImporter.new(@filename,@filepath)
  end

  test 'downloads countries dump table' do

    file_mock = mock()
    file_mock.stubs(:read).returns(true)

    bucket_mock = mock()
    bucket_mock.stubs(:objects).returns({'countries_geometries_dump.tar.gz' => file_mock})

    s3_mock = mock()
    s3_mock.stubs(:buckets).returns({'ppe.datasets' => bucket_mock})

    AWS::S3.expects(:new).returns(s3_mock)

    countries_geometries = CountriesGeometryImporter.new(@filename,@filepath)
    countries_geometries.download_countries_geometries

  end

  test 'imports countries dump table' do


    countries_geometries = CountriesGeometryImporter.new(@filename,@filepath)
    
    countries_geometries.expects(:system).
    with("pg_restore -c -i -U postgres -d pp_development -v #{@filepath}").
    returns(true)



    response =  countries_geometries.restore_table
    assert response, "Expected restore_table to return true on success"
  end


  test 'updates countries table' do
    type = 'LAND'
    country = 'POL'
    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        UPDATE countries
        SET land_geom = the_geom
        FROM (SELECT ST_Collectionextract(ST_collect(the_geom),3) the_geom
                FROM countries_geometries_temp
                WHERE type = 'LAND' AND iso_3 = 'POL') a 
        WHERE iso_3 = 'POL'
      """.squish).
      returns(true)

    countries_geometries = CountriesGeometryImporter.new(@filename,@filepath)
    response = countries_geometries.update_table type, country
    assert response, "Expected update_table to return true on success"

  end


  test 'creates indexes' do
    ActiveRecord::Base.connection.
      expects(:execute).
      with("""CREATE INDEX land_geom_gindx ON countries USING GIST (land_geom);
              CREATE INDEX eez_geom_gindx ON countries USING GIST (eez_geom);
              CREATE INDEX ts_geom_gindx ON countries USING GIST (ts_geom);""".squish).
      returns(true)

    countries_geometries = CountriesGeometryImporter.new(@filename,@filepath)
    response = countries_geometries.create_indexes
    assert response, "Expected update_table to return true on success"

  end

  test 'deletes old table' do
    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        DELETE FROM countries_geometries_temp
      """.squish).
      returns(true)
    countries_geometries = CountriesGeometryImporter.new(@filename,@filepath)
    response = countries_geometries.delete_temp_table
    assert response, "Expected delete_table to return true on success"
  end

  test 'deletes temp file' do

    File.expects(:delete).returns(true)

    countries_geometries = CountriesGeometryImporter.new(@filename,@filepath)
    response = countries_geometries.delete_temp_file
    assert response, "Expected delete_table to return true on success"
  end



end