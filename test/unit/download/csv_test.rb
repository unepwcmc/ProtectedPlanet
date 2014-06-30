require 'test_helper'

class DownloadCsvTest < ActiveSupport::TestCase
  test '#generate, given a path, calls ogr2ogr with the path, a query,
   and the specific driver' do
    zip_file_path = './all-csv.zip'
    csv_file_path = './all-csv.csv'
    query = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME}"

    view_name = 'temporary_view_all'
    Download::Csv.any_instance.expects(:with_view).with(query).yields(view_name).returns(true)

    Download::Csv.
      any_instance.
      expects(:system).
      with("zip -j #{zip_file_path} #{csv_file_path}").
      returns(true)
    Ogr::Postgres.expects(:export).with(:csv, csv_file_path, "SELECT * FROM #{view_name}").returns(true)

    assert_equal true, Download::Csv.generate(zip_file_path),
      "Expected #generate to return true on success"
  end

  test '#generate returns false if the export fails' do
    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.expects(:export).returns(false)

    assert_equal false, Download::Csv.generate(''),
      "Expected #generate to return false on failure"
  end

  test '#generate returns false if the zip fails' do
    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.expects(:export).returns(true)
    Download::Csv.any_instance.expects(:system).returns(false)

    assert_equal false, Download::Csv.generate(''),
      "Expected #generate to return false on failure"
  end

  test '#generate removes non-zip files when finished' do
    csv_path = './all-csv.csv'

    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.stubs(:export).returns(true)
    Download::Csv.any_instance.stubs(:system).returns(true)

    FileUtils.expects(:rm_rf).with(csv_path)

    Download::Csv.generate('./all-csv.zip')
  end

  test '#generate, given a path and WDPA IDs, calls ogr2ogr with the path, a query,
   and the specific driver' do
    zip_file_path = './all-csv.zip'
    csv_file_path = './all-csv.csv'

    wdpa_ids = [1,2,3]
    query = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME} WHERE wdpaid IN (1,2,3)"

    view_name = 'temporary_view_123'
    Download::Csv.any_instance.stubs(:with_view).with(query).yields(view_name).returns(true)

    zip_command = "zip -j #{zip_file_path} #{csv_file_path}"
    Download::Csv.any_instance.expects(:system).with(zip_command).returns(true)

    Ogr::Postgres.expects(:export).with(:csv, csv_file_path, "SELECT * FROM #{view_name}").returns(true)

    assert_equal true, Download::Csv.generate(zip_file_path, wdpa_ids),
      'Expected #generate to return true on success'
  end
end
