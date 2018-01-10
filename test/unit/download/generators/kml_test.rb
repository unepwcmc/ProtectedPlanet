require 'test_helper'

class DownloadKmlTest < ActiveSupport::TestCase
  test '#generate, given a path, calls ogr2ogr with the path, a query,
   and the specific driver' do
    zip_file_path = './all-kml.zip'
    kml_file_path = './all-kml.kml'
    wdpa_file_path = 'WDPA_sources.csv'
    query = """
      SELECT \"TYPE\", #{Download::Utils.download_columns}
      FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}
    """.squish

    view_name = 'temporary_view_123'
    Download::Generators::Kml.any_instance.expects(:create_view).with(query).returns(view_name)

    create_zip_command = "zip -j #{zip_file_path} #{kml_file_path}"
    Download::Generators::Kml.any_instance.expects(:system).with(create_zip_command).returns(true)

    wdpa_zip_command = "zip -ru #{zip_file_path} #{wdpa_file_path}"
    opts = {chdir: "."}
    Download::Generators::Kml.any_instance.expects(:system).with(wdpa_zip_command, opts).returns(true)

    update_zip_command = "zip -ru #{zip_file_path} *"
    opts = {chdir: Download::Generators::Base::ATTACHMENTS_PATH}
    Download::Generators::Kml.any_instance.expects(:system).with(update_zip_command, opts).returns(true)

    Ogr::Postgres.expects(:export).with(:kml, kml_file_path, "SELECT * FROM #{view_name}").returns(true)

    assert_equal true, Download::Generators::Kml.generate(zip_file_path),
      "Expected #generate to return true on success"
  end

  test '#generate returns false if the export fails' do
    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.expects(:export).returns(false)

    assert_equal false, Download::Generators::Kml.generate(''),
      "Expected #generate to return false on failure"
  end

  test '#generate returns false if the zip fails' do
    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.expects(:export).returns(true)
    Download::Generators::Kml.any_instance.expects(:system).returns(false)

    assert_equal false, Download::Generators::Kml.generate(''),
      "Expected #generate to return false on failure"
  end

  test '#generate removes non-zip files when finished' do
    kml_path = './all.kml'

    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.stubs(:export).returns(true)
    Download::Generators::Kml.any_instance.stubs(:system).returns(true)

    FileUtils.expects(:rm_rf).with(kml_path)

    Download::Generators::Kml.generate('./all.zip')
  end

  test '#generate creates a download view' do
    Download::Generators::Kml.any_instance.stubs(:system).returns(true)

    pa = FactoryGirl.create(:protected_area, wdpa_id: 1234)
    view_name = "tmp_downloads_4db53fd3381d6de4cbcfd5489917d712391fc484"

    Ogr::Postgres
      .expects(:export)
      .with(:kml, './pa-kml.kml', "SELECT * FROM #{view_name}")
      .returns(true)


    ActiveRecord::Base.connection.expects(:execute).with("""
      CREATE OR REPLACE VIEW #{view_name} AS
      SELECT \"TYPE\", #{Download::Utils.download_columns} FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME} WHERE \"WDPAID\" IN (#{pa.wdpa_id})
    """.squish)

    Download::Generators::Kml.generate('./pa-kml.zip', [pa.wdpa_id])
  end

  test '#generate, given a path and WDPA IDs, calls ogr2ogr with the
   path, a query, and the specific driver' do
    zip_file_path = './all-kml.zip'
    kml_file_path = './all-kml.kml'
    wdpa_file_path = 'WDPA_sources.csv'

    wdpa_ids = [1,2,3]
    query = """
      SELECT \"TYPE\", #{Download::Utils.download_columns}
      FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}
      WHERE \"WDPAID\" IN (1,2,3)
    """.squish

    view_name = 'temporary_view_123'
    Download::Generators::Kml.any_instance.stubs(:create_view).with(query).returns(view_name)

    create_zip_command = "zip -j #{zip_file_path} #{kml_file_path}"
    Download::Generators::Kml.any_instance.expects(:system).with(create_zip_command).returns(true)

    wdpa_zip_command = "zip -ru #{zip_file_path} #{wdpa_file_path}"
    opts = {chdir: "."}
    Download::Generators::Kml.any_instance.expects(:system).with(wdpa_zip_command, opts).returns(true)

    update_zip_command = "zip -ru #{zip_file_path} *"
    opts = {chdir: Download::Generators::Base::ATTACHMENTS_PATH}
    Download::Generators::Kml.any_instance.expects(:system).with(update_zip_command, opts).returns(true)

    Ogr::Postgres.expects(:export).with(:kml, kml_file_path, "SELECT * FROM #{view_name}").returns(true)

    assert Download::Generators::Kml.generate(zip_file_path, wdpa_ids),
      "Expected #generate to return true on success"
  end
end
