require 'test_helper'

class DownloadKmlTest < ActiveSupport::TestCase
  test '#generate, given a path, calls ogr2ogr with the path, a query,
   and the specific driver' do
    zip_file_path = './all-kml.zip'
    kml_file_path = './all-kml.kml'
    query = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME}"

    view_name = 'temporary_view_123'
    Download::Generators::Kml.any_instance.stubs(:with_view).with(query).yields(view_name).returns(true)

    toc_path = "#{Rails.root}/lib/data/documents/Terms_of_Use.pdf"
    data_standard_path = "#{Rails.root}/lib/data/documents/WDPA_Data_Standards.pdf"
    attachments_path = "#{toc_path} #{data_standard_path}"

    zip_command = "zip -j #{zip_file_path} #{kml_file_path} #{attachments_path}"
    Download::Generators::Kml.any_instance.expects(:system).with(zip_command).returns(true)

    Ogr::Postgres.expects(:export).with(:kml, kml_file_path, "SELECT * FROM #{view_name}").returns(true)

    assert Download::Generators::Kml.generate(zip_file_path),
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

  test '#generate creates a temporary download view and drops it after use' do
    Download::Generators::Kml.any_instance.stubs(:system).returns(true)

    pa = FactoryGirl.create(:protected_area, wdpa_id: 1234)
    view_name = "tmp_downloads_fac1733ca468c25058e80c9ecf1708818c82d090"

    Ogr::Postgres
      .expects(:export)
      .with(:kml, './pa-kml.kml', "SELECT * FROM #{view_name}")
      .returns(true)

    optional_drop_query = "DROP VIEW IF EXISTS #{view_name}"
    drop_query = "DROP VIEW #{view_name}"
    create_query = """
      CREATE VIEW #{view_name} AS
      SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME} WHERE wdpaid IN (#{pa.wdpa_id})
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(optional_drop_query)
    ActiveRecord::Base.connection.expects(:execute).with(create_query)
    ActiveRecord::Base.connection.expects(:execute).with(drop_query)

    Download::Generators::Kml.generate('./pa-kml.zip', [pa.wdpa_id])
  end

  test '#generate, given a path and WDPA IDs, calls ogr2ogr with the
   path, a query, and the specific driver' do
    zip_file_path = './all-kml.zip'
    kml_file_path = './all-kml.kml'

    wdpa_ids = [1,2,3]
    query = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME} WHERE wdpaid IN (1,2,3)"

    view_name = 'temporary_view_123'
    Download::Generators::Kml.any_instance.stubs(:with_view).with(query).yields(view_name).returns(true)

    toc_path = "#{Rails.root}/lib/data/documents/Terms_of_Use.pdf"
    data_standard_path = "#{Rails.root}/lib/data/documents/WDPA_Data_Standards.pdf"
    attachments_path = "#{toc_path} #{data_standard_path}"

    zip_command = "zip -j #{zip_file_path} #{kml_file_path} #{attachments_path}"
    Download::Generators::Kml.any_instance.expects(:system).with(zip_command).returns(true)

    Ogr::Postgres.expects(:export).with(:kml, kml_file_path, "SELECT * FROM #{view_name}").returns(true)

    assert Download::Generators::Kml.generate(zip_file_path, wdpa_ids),
      "Expected #generate to return true on success"
  end
end
