require 'test_helper'

class DownloadGeneratorsCsvTest < ActiveSupport::TestCase
  SOURCES_LABEL = 'Jan2024'.freeze
  SOURCES_FILE  = "WDPA_sources_#{SOURCES_LABEL}.csv".freeze

  # The portal-release path is the standard one now: it selects from the portal
  # downloads view and uses the SITE_ID column. Pin it (and the release label) so
  # the generated SQL and the sources filename are deterministic rather than
  # dependent on whether a portal release row happens to exist in the test DB.
  #
  # export_sources is a separate concern from what these tests assert (the main
  # export + zipping), so it is stubbed out. The original tests tried to do this
  # via File.stubs(:exists?), which never took effect because the code calls
  # File.exist? (no trailing "s").
  setup do
    Download::Config.stubs(:has_successful_portal_release?).returns(true)
    Download::Config.stubs(:current_label).returns(SOURCES_LABEL)
    Download::Generators::Csv.any_instance.stubs(:export_sources).returns(true)
  end

  test '#generate, given a path, calls ogr2ogr with the path, a query,
   and the specific driver' do
    zip_file_path = './all-csv.zip'
    csv_file_path = './all-csv.csv'
    query = "
      SELECT \"TYPE\", #{Download::Utils.download_columns}
      FROM #{Download::Config.downloads_view}
    ".squish

    view_name = 'temporary_view_all'
    Download::Generators::Csv.any_instance.expects(:create_view).with(query).returns(view_name)

    create_zip_command = "zip -j #{zip_file_path} #{csv_file_path}"
    Download::Generators::Csv.any_instance.expects(:system).with(create_zip_command).returns(true)

    wdpa_zip_command = "zip -ru #{zip_file_path} #{SOURCES_FILE}"
    Download::Generators::Csv.any_instance.expects(:system).with(wdpa_zip_command, chdir: '.').returns(true)

    update_zip_command = "zip -ru #{zip_file_path} *"
    opts = { chdir: Download::Generators::Base::ATTACHMENTS_PATH }
    Download::Generators::Csv.any_instance.expects(:system).with(update_zip_command, **opts).returns(true)

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
    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.expects(:export).returns(true)

    Download::Generators::Csv.any_instance.expects(:system).returns(false)

    wdpa_zip_command = "zip -ru  #{SOURCES_FILE}"
    Download::Generators::Csv.any_instance.expects(:system).with(wdpa_zip_command, chdir: '.').returns(true)

    update_zip_command = 'zip -ru  *'
    opts = { chdir: Download::Generators::Base::ATTACHMENTS_PATH }
    Download::Generators::Csv.any_instance.expects(:system).with(update_zip_command, **opts).returns(false)

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

    site_ids = [1, 2, 3]
    # add_conditions wraps the site-id disjuncts in parentheses so they are
    # treated as one unit when AND-ed with any other filters.
    query = "
      SELECT \"TYPE\", #{Download::Utils.download_columns}
      FROM #{Download::Config.downloads_view}
      WHERE (\"SITE_ID\" IN (1,2,3))
    ".squish

    view_name = 'temporary_view_123'
    Download::Generators::Csv.any_instance.stubs(:create_view).with(query).returns(view_name)

    create_zip_command = "zip -j #{zip_file_path} #{csv_file_path}"
    Download::Generators::Csv.any_instance.expects(:system).with(create_zip_command).returns(true)

    wdpa_zip_command = "zip -ru #{zip_file_path} #{SOURCES_FILE}"
    Download::Generators::Csv.any_instance.expects(:system).with(wdpa_zip_command, chdir: '.').returns(true)

    update_zip_command = "zip -ru #{zip_file_path} *"
    opts = { chdir: Download::Generators::Base::ATTACHMENTS_PATH }
    Download::Generators::Csv.any_instance.expects(:system).with(update_zip_command, **opts).returns(true)

    Ogr::Postgres.expects(:export).with(:csv, csv_file_path, "SELECT * FROM #{view_name}").returns(true)

    assert_equal true, Download::Generators::Csv.generate(zip_file_path, { site_ids: site_ids }),
      'Expected #generate to return true on success'
  end
end
