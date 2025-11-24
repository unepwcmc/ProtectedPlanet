require 'test_helper'

class DownloadTest < ActiveSupport::TestCase
  test '.generate, called with a name and no PA ids, generates download
   files for all countries' do
    download_name = 'an_download'

    shapefile_download_zip_name = 'an_download-shapefile.zip'
    shapefile_zip_path = File.join(Rails.root, 'tmp', shapefile_download_zip_name)
    Download::Generators::Shapefile.expects(:generate).with(shapefile_zip_path, nil).returns(true)
    S3.expects(:upload).with(Download::CURRENT_PREFIX + shapefile_download_zip_name, shapefile_zip_path)

    csv_download_zip_name = 'an_download-csv.zip'
    csv_zip_path = File.join(Rails.root, 'tmp', csv_download_zip_name)
    Download::Generators::Csv.expects(:generate).with(csv_zip_path, nil).returns(true)
    S3.expects(:upload).with(Download::CURRENT_PREFIX + csv_download_zip_name, csv_zip_path)

    download_success = Download.generate download_name
    assert download_success, "Expected Download.generate to return true on success"
  end

  test '.generate, called with the import option, generates downloads with the import prefix' do
    download_name = 'an_download'

    Download::Generators::Shapefile.stubs(:generate).returns(true)
    S3.expects(:upload).with(Download::IMPORT_PREFIX + 'an_download-shapefile.zip', anything)

    Download::Generators::Csv.stubs(:generate).returns(true)
    S3.expects(:upload).with(Download::IMPORT_PREFIX + 'an_download-csv.zip', anything)

    Download.generate download_name, for_import: true
  end

  test '.generate, called with an array of PA IDs, generates downloads
   for the given IDs' do
    download_name = 'an_download'
    pa_ids = [1,2,3]

    S3.stubs(:upload)

    shapefile_zip_path = File.join(Rails.root, 'tmp', 'an_download-shapefile.zip')
    Download::Generators::Shapefile.expects(:generate).with(shapefile_zip_path, pa_ids)

    csv_zip_path = File.join(Rails.root, 'tmp', 'an_download-csv.zip')
    Download::Generators::Csv.expects(:generate).with(csv_zip_path, pa_ids)

    download_success = Download.generate download_name, site_ids: pa_ids
    assert download_success, "Expected Download.generate to return true on success"
  end

  test '.generate removes the zip after uploading to S3' do
    Download::Generators::Shapefile.stubs(:generate).returns(true)
    Download::Generators::Csv.stubs(:generate).returns(true)
    S3.stubs(:upload)

    shapefile_zip_path = File.join(Rails.root, 'tmp', 'an_download-shapefile.zip')
    FileUtils.expects(:rm_rf).with(shapefile_zip_path)

    csv_zip_path = File.join(Rails.root, 'tmp', 'an_download-csv.zip')
    FileUtils.expects(:rm_rf).with(csv_zip_path)

    Download.generate 'an_download'
  end

  test '.generate does not upload to S3 if a Generator returns
   false' do
    Download::Generators::Csv.stubs(:generate).returns(true)
    Download::Generators::Shapefile.expects(:generate).returns(false)

    S3.expects(:upload).once

    Download.generate 'an_download'
  end

  test '.request, given an hash of params, requests the router with
   domain and params' do
    params = {'domain' => 'general', 'id' => 'USA'}
    Download::Router.expects(:request).with('general', {'id' => 'USA'})

    Download.request params
  end

  test '.set_email, given an hash of params, sets email using the router' do
    params = {'domain' => 'general', 'id' => '123', 'email' => 'test@test.com'}
    Download::Router.expects(:set_email).with('general', {'id' => '123', 'email' => 'test@test.com'})

    Download.set_email params
  end
end
