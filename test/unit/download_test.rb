require 'test_helper'

class DownloadTest < ActiveSupport::TestCase
  test '.generate, called with a name and no PA ids, generates download
   files for all countries' do
    download_name = 'an_download'

    shapefile_download_zip_name = 'an_download-shapefile.zip'
    shapefile_zip_path = File.join(Rails.root, 'tmp', shapefile_download_zip_name)
    Download::Shapefile.expects(:generate).with(shapefile_zip_path)
    S3.expects(:upload).with(shapefile_download_zip_name, shapefile_zip_path)

    csv_download_zip_name = 'an_download-csv.zip'
    csv_zip_path = File.join(Rails.root, 'tmp', csv_download_zip_name)
    Download::Csv.expects(:generate).with(csv_zip_path)
    S3.expects(:upload).with(csv_download_zip_name, csv_zip_path)

    kml_download_zip_name = 'an_download-kml.zip'
    kml_zip_path = File.join(Rails.root, 'tmp', kml_download_zip_name)
    Download::Kml.expects(:generate).with(kml_zip_path)
    S3.expects(:upload).with(kml_download_zip_name, kml_zip_path)

    download_success = Download.generate download_name
    assert download_success, "Expected Download.generate to return true on success"
  end
end
