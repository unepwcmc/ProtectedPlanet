require 'test_helper'

class DownloadTest < ActiveSupport::TestCase
  test '.generate, called with no arguments, generates download files for all countries' do
    shapefile_zip_path = File.join(Rails.root, 'tmp', "all-shapefile.zip")
    Download::Shapefile.expects(:generate).with(shapefile_zip_path)
    S3.expects(:upload).with(shapefile_zip_path)

    csv_zip_path = File.join(Rails.root, 'tmp', "all-csv.zip")
    Download::Csv.expects(:generate).with(csv_zip_path)
    S3.expects(:upload).with(csv_zip_path)

    kml_zip_path = File.join(Rails.root, 'tmp', "all-kml.zip")
    Download::Kml.expects(:generate).with(kml_zip_path)
    S3.expects(:upload).with(kml_zip_path)

    download_success = Download.generate
    assert download_success, "Expected Download.generate to return true on success"
  end
end
