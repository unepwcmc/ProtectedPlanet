require 'test_helper'

class DownloadCsvTest < ActiveSupport::TestCase
  test '#generate, given a path, calls ogr2ogr with the path, a query,
   and the specific driver' do
    zip_file_path = './all-csv.zip'
    csv_file_path = './all-csv.csv'
    query = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME}"

    Download::Csv.
      any_instance.
      expects(:system).
      with("zip -j #{zip_file_path} #{csv_file_path}").
      returns(true)
    Ogr::Postgres.expects(:export).with(:csv, csv_file_path, query).returns(true)

    assert_equal true, Download::Csv.generate(zip_file_path),
      "Expected #generate to return true on success"
  end

  test '#generate returns false if the export fails' do
    Ogr::Postgres.expects(:export).returns(false)

    assert_equal false, Download::Csv.generate(''),
      "Expected #generate to return false on failure"
  end

  test '#generate returns false if the zip fails' do
    Ogr::Postgres.expects(:export).returns(true)
    Download::Csv.any_instance.expects(:system).returns(false)

    assert_equal false, Download::Csv.generate(''),
      "Expected #generate to return false on failure"
  end

  test '#generate, given a path and WDPA IDs, calls ogr2ogr with the path, a query,
   and the specific driver' do
    zip_file_path = './all-csv.zip'
    csv_file_path = './all-csv.csv'

    wdpa_ids = [1,2,3]
    query = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME} WHERE wdpaid IN (1,2,3)"

    Download::Csv.
      any_instance.
      expects(:system).
      with("zip -j #{zip_file_path} #{csv_file_path}").
      returns(true)
    Ogr::Postgres.expects(:export).with(:csv, csv_file_path, query).returns(true)

    assert Download::Csv.generate(zip_file_path, wdpa_ids),
      "Expected #generate to return true on success"
  end
end
