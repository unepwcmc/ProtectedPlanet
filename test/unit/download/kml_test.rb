require 'test_helper'

class DownloadKmlTest < ActiveSupport::TestCase
  test '#generate, given a path, calls ogr2ogr with the path, a query,
   and the specific driver' do
    zip_file_path = './all-kml.zip'
    kml_file_path = './all-kml.kml'
    query = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME}"

    Download::Kml.
      any_instance.
      expects(:system).
      with("zip -j #{zip_file_path} #{kml_file_path}").
      returns(true)
    Ogr::Postgres.expects(:export).with(:kml, kml_file_path, query).returns(true)

    assert Download::Kml.generate(zip_file_path),
      "Expected #generate to return true on success"
  end

  test '#generate returns false if the export fails' do
    Ogr::Postgres.expects(:export).returns(false)

    assert_equal false, Download::Kml.generate(''),
      "Expected #generate to return false on failure"
  end

  test '#generate returns false if the zip fails' do
    Ogr::Postgres.expects(:export).returns(true)
    Download::Kml.any_instance.expects(:system).returns(false)

    assert_equal false, Download::Kml.generate(''),
      "Expected #generate to return false on failure"
  end

  test '#generate removes non-zip files when finished' do
    kml_path = './all.kml'

    Ogr::Postgres.stubs(:export).returns(true)
    Download::Kml.any_instance.stubs(:system).returns(true)

    FileUtils.expects(:rm_rf).with(kml_path)

    Download::Kml.generate('./all.zip')
  end

  test '#generate, given a path and WDPA IDs, calls ogr2ogr with the
   path, a query, and the specific driver' do
    zip_file_path = './all-kml.zip'
    kml_file_path = './all-kml.kml'

    wdpa_ids = [1,2,3]
    query = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME} WHERE wdpaid IN (1,2,3)"

    Download::Kml.
      any_instance.
      expects(:system).
      with("zip -j #{zip_file_path} #{kml_file_path}").
      returns(true)
    Ogr::Postgres.expects(:export).with(:kml, kml_file_path, query).returns(true)

    assert Download::Kml.generate(zip_file_path, wdpa_ids),
      "Expected #generate to return true on success"
  end
end
