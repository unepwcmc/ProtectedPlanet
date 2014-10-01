require 'test_helper'

class DownloadTest < ActiveSupport::TestCase
  test '.generate, called with a name and no PA ids, generates download
   files for all countries' do
    download_name = 'an_download'

    shapefile_download_zip_name = 'an_download-shapefile.zip'
    shapefile_zip_path = File.join(Rails.root, 'tmp', shapefile_download_zip_name)
    Download::Shapefile.expects(:generate).with(shapefile_zip_path, nil).returns(true)
    S3.expects(:upload).with(Download::CURRENT_PREFIX + shapefile_download_zip_name, shapefile_zip_path)

    csv_download_zip_name = 'an_download-csv.zip'
    csv_zip_path = File.join(Rails.root, 'tmp', csv_download_zip_name)
    Download::Csv.expects(:generate).with(csv_zip_path, nil).returns(true)
    S3.expects(:upload).with(Download::CURRENT_PREFIX + csv_download_zip_name, csv_zip_path)

    kml_download_zip_name = 'an_download-kml.zip'
    kml_zip_path = File.join(Rails.root, 'tmp', kml_download_zip_name)
    Download::Kml.expects(:generate).with(kml_zip_path, nil).returns(true)
    S3.expects(:upload).with(Download::CURRENT_PREFIX + kml_download_zip_name, kml_zip_path)

    download_success = Download.generate download_name
    assert download_success, "Expected Download.generate to return true on success"
  end

  test '.generate, called with the import option, generates downloads with the import prefix' do
    download_name = 'an_download'

    Download::Shapefile.stubs(:generate).returns(true)
    S3.expects(:upload).with(Download::IMPORT_PREFIX + 'an_download-shapefile.zip', anything)

    Download::Csv.stubs(:generate).returns(true)
    S3.expects(:upload).with(Download::IMPORT_PREFIX + 'an_download-csv.zip', anything)

    Download::Kml.stubs(:generate).returns(true)
    S3.expects(:upload).with(Download::IMPORT_PREFIX + 'an_download-kml.zip', anything)

    Download.generate download_name, for_import: true
  end

  test '.generate, called with an array of PA IDs, generates downloads
   for the given IDs' do
    download_name = 'an_download'
    pa_ids = [1,2,3]

    S3.stubs(:upload)

    shapefile_zip_path = File.join(Rails.root, 'tmp', 'an_download-shapefile.zip')
    Download::Shapefile.expects(:generate).with(shapefile_zip_path, pa_ids)

    csv_zip_path = File.join(Rails.root, 'tmp', 'an_download-csv.zip')
    Download::Csv.expects(:generate).with(csv_zip_path, pa_ids)

    kml_zip_path = File.join(Rails.root, 'tmp', 'an_download-kml.zip')
    Download::Kml.expects(:generate).with(kml_zip_path, pa_ids)

    download_success = Download.generate download_name, wdpa_ids: pa_ids
    assert download_success, "Expected Download.generate to return true on success"
  end

  test '.generate removes the zip after uploading to S3' do
    Download::Shapefile.stubs(:generate).returns(true)
    Download::Kml.stubs(:generate).returns(true)
    Download::Csv.stubs(:generate).returns(true)
    S3.stubs(:upload)

    shapefile_zip_path = File.join(Rails.root, 'tmp', 'an_download-shapefile.zip')
    FileUtils.expects(:rm_rf).with(shapefile_zip_path)

    csv_zip_path = File.join(Rails.root, 'tmp', 'an_download-csv.zip')
    FileUtils.expects(:rm_rf).with(csv_zip_path)

    kml_zip_path = File.join(Rails.root, 'tmp', 'an_download-kml.zip')
    FileUtils.expects(:rm_rf).with(kml_zip_path)

    Download.generate 'an_download'
  end

  test '.generate does not upload to S3 if a Generator returns
   false' do
    Download::Csv.stubs(:generate).returns(true)
    Download::Kml.stubs(:generate).returns(true)
    Download::Shapefile.expects(:generate).returns(false)

    S3.expects(:upload).twice

    Download.generate 'an_download'
  end

  test '.link_to, given a name and a type, returns a link to the
   download S3 bucket for that object name' do
    download_name = 'that-download'
    type = :csv

    Rails.application.secrets.aws_downloads_bucket = 'pp-downloads-development'

    expected_url = "https://pp-downloads-development.s3.amazonaws.com/#{Download::CURRENT_PREFIX}that-download-csv.zip"
    url = Download.link_to download_name, type

    assert_equal expected_url, url
  end

  test '.make_current moves all downloads to current folder in S3' do
    S3.expects(:replace_all).with(Download::IMPORT_PREFIX, Download::CURRENT_PREFIX)
    Download.make_current
  end
end
