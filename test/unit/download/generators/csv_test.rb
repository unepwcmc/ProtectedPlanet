require 'test_helper'

class DownloadGeneratorsCsvTest < ActiveSupport::TestCase
  test '#generate, given a path, calls ogr2ogr with the path, a query,
   and the specific driver' do
    zip_file_path = './all-csv.zip'
    csv_file_path = './all-csv.csv'
    wdpa_file_path = 'WDPA_sources.csv'
    query = "
      SELECT \"TYPE\", #{Download::Utils.download_columns}
      FROM #{Wdpa::Portal::Config::PortalImportConfig::PORTAL_VIEWS['downloads']}
    ".squish

    File.stubs(:exists?).with('./WDPA_sources.csv').returns(true)

    view_name = 'temporary_view_all'
    Download::Generators::Csv.any_instance.expects(:create_view).with(query).returns(view_name)

    create_zip_command = "zip -j #{zip_file_path} #{csv_file_path}"
    Download::Generators::Csv.any_instance.expects(:system).with(create_zip_command).returns(true)

    wdpa_zip_command = "zip -ru #{zip_file_path} #{wdpa_file_path}"
    opts = { chdir: '.' }
    Download::Generators::Csv.any_instance.expects(:system).with(wdpa_zip_command, opts).returns(true)

    update_zip_command = "zip -ru #{zip_file_path} *"
    opts = { chdir: Download::Generators::Base::ATTACHMENTS_PATH }
    Download::Generators::Csv.any_instance.expects(:system).with(update_zip_command, opts).returns(true)

    Ogr::Postgres.expects(:export).with(:csv, csv_file_path, "SELECT * FROM #{view_name}").returns(true)

    assert_equal true, Download::Generators::Csv.generate(zip_file_path),
      'Expected #generate to return true on success'
  end

  test '#generate returns false if the export fails' do
    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.expects(:export).returns(false)

    assert_equal false, Download::Generators::Csv.generate(''),
      'Expected #generate to return false on failure'
  end

  test '#generate returns false if the zip fails' do
    wdpa_file_path = 'WDPA_sources.csv'
    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.expects(:export).returns(true)
    File.stubs(:exists?).with('./WDPA_sources.csv').returns(true)

    Download::Generators::Csv.any_instance.expects(:system).returns(false)

    wdpa_zip_command = "zip -ru  #{wdpa_file_path}"
    opts = { chdir: '.' }
    Download::Generators::Csv.any_instance.expects(:system).with(wdpa_zip_command, opts).returns(true)

    update_zip_command = 'zip -ru  *'
    opts = { chdir: Download::Generators::Base::ATTACHMENTS_PATH }
    Download::Generators::Csv.any_instance.expects(:system).with(update_zip_command, opts).returns(false)

    assert_equal false, Download::Generators::Csv.generate(''),
      'Expected #generate to return false on failure'
  end

  test '#generate removes non-zip files when finished' do
    csv_path = './all-csv.csv'

    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.stubs(:export).returns(true)
    Download::Generators::Csv.any_instance.stubs(:system).returns(true)

    FileUtils.expects(:rm_rf).with(csv_path)

    Download::Generators::Csv.generate('./all-csv.zip')
  end

  test '#generate, given a path and SITE IDs, calls ogr2ogr with the path, a query,
   and the specific driver' do
    zip_file_path = './all-csv.zip'
    csv_file_path = './all-csv.csv'
    wdpa_file_path = 'WDPA_sources.csv'

    site_ids = [1, 2, 3]
    query = "
      SELECT \"TYPE\", #{Download::Utils.download_columns}
      FROM #{Wdpa::Portal::Config::PortalImportConfig::PORTAL_VIEWS['downloads']}
      WHERE \"SITE_ID\" IN (1,2,3)
    ".squish

    File.stubs(:exists?).with('./WDPA_sources.csv').returns(true)

    view_name = 'temporary_view_123'
    Download::Generators::Csv.any_instance.stubs(:create_view).with(query).returns(view_name)

    create_zip_command = "zip -j #{zip_file_path} #{csv_file_path}"
    Download::Generators::Csv.any_instance.expects(:system).with(create_zip_command).returns(true)

    wdpa_zip_command = "zip -ru #{zip_file_path} #{wdpa_file_path}"
    opts = { chdir: '.' }
    Download::Generators::Csv.any_instance.expects(:system).with(wdpa_zip_command, opts).returns(true)

    update_zip_command = "zip -ru #{zip_file_path} *"
    opts = { chdir: Download::Generators::Base::ATTACHMENTS_PATH }
    Download::Generators::Csv.any_instance.expects(:system).with(update_zip_command, opts).returns(true)

    Ogr::Postgres.expects(:export).with(:csv, csv_file_path, "SELECT * FROM #{view_name}").returns(true)

    assert_equal true, Download::Generators::Csv.generate(zip_file_path, site_ids),
      'Expected #generate to return true on success'
  end
end
