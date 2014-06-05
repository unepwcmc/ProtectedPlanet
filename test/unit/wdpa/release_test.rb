require 'test_helper'

class TestWdpaRelease < ActiveSupport::TestCase
  test '#download downloads from S3, creates a WDPA GDB and returns an
   instance of itself' do
    zip_path = "zip_path"
    Wdpa::Release.any_instance.expects(:zip_path).returns(zip_path).at_least_once
    gdb_path = "gdb_path"
    Wdpa::Release.any_instance.expects(:gdb_path).returns(gdb_path).at_least_once

    Wdpa::S3Downloader.any_instance.
      expects(:save_current_wdpa_to).
      with(filename: zip_path)

    Wdpa::Release.any_instance.
      expects(:system).
      with("unzip -j '#{zip_path}' '\*.gdb/\*' -d '#{gdb_path}'")

    Ogr::Postgres.any_instance.
      expects(:import).
      with(file: gdb_path)

    assert_kind_of Wdpa::Release, Wdpa::Release.download
  end

  test '.zip_path returns the target location of the zip with the current time' do
    start_time = Time.parse("2013-05-30 14:23")
    Timecop.freeze start_time

    wdpa_release = Wdpa::Release.new
    expected_path = File.join(Rails.root, 'tmp', "wdpa-2013-05-30-1423.zip")

    assert_equal expected_path, wdpa_release.zip_path

    Timecop.return
  end

  test '.gdb_path returns the target location of the GDB with the current time' do
    start_time = Time.parse("2013-05-30 14:23")
    Timecop.freeze start_time

    wdpa_release = Wdpa::Release.new
    expected_path = File.join(Rails.root, 'tmp', "wdpa-2013-05-30-1423.gdb")

    assert_equal expected_path, wdpa_release.gdb_path

    Timecop.return
  end

  test '.geometry_tables returns the geometry tables for the current gdb
   file' do
    gdb_path = "gdb_path"
    Wdpa::Release.any_instance.expects(:gdb_path).returns(gdb_path).at_least_once

    geometry_tables = ["wdpapoly_jun2014", "wdpa_point"]
    ogr_info_mock = mock()
    ogr_info_mock.
      expects(:layers_matching).
      with(/wdpa_?po/i).
      returns(geometry_tables)
    Ogr::Info.expects(:new).with(gdb_path).returns(ogr_info_mock)

    wdpa_release = Wdpa::Release.new
    assert_equal geometry_tables, wdpa_release.geometry_tables
  end

  test '.geometry_tables only returns geometry tables from the GDB' do
    gdb_path = "gdb_path"
    Wdpa::Release.any_instance.expects(:gdb_path).returns(gdb_path).at_least_once

    tables = ["wdpapoly_jun2014", "wdpa_point", "wdpa_source"]
    Ogr::Info.any_instance.
      expects(:layers).
      returns(tables)

    wdpa_release = Wdpa::Release.new
    assert_equal tables[0..1], wdpa_release.geometry_tables
  end

  test '.source_table only returns the source table from the GDB' do
    gdb_path = "gdb_path"
    Wdpa::Release.any_instance.expects(:gdb_path).returns(gdb_path).at_least_once

    tables = ["wdpapoly_jun2014", "wdpa_point", "wdpa_source"]
    Ogr::Info.any_instance.
      expects(:layers).
      returns(tables)

    wdpa_release = Wdpa::Release.new
    assert_equal tables[2], wdpa_release.source_table
  end

  test '.protected_areas returns an array of protected area attributes
   from the import table' do
    pa_attributes = [{
      "wdpaid" => 1234
    },{
      "wdpaid" => 4321
    }, {
      "wdpaid" => 6789
    }]

    geometry_tables = ["wdpa_poly", "wdpa_point"]

    pg_result_mock = mock()
    pg_result_mock.expects(:to_a).returns(pa_attributes[0..1])
    pg_result_mock.expects(:to_a).returns(pa_attributes[2])

    connection_mock = mock()
    connection_mock.
      stubs(:execute).
      with("SELECT * FROM #{geometry_tables.first}").
      returns(pg_result_mock)

    connection_mock.
      stubs(:execute).
      with("SELECT * FROM #{geometry_tables.second}").
      returns(pg_result_mock)

    ActiveRecord::Base.expects(:connection).returns(connection_mock)

    wdpa_release = Wdpa::Release.new
    wdpa_release.expects(:geometry_tables).returns(geometry_tables)

    assert_same_elements pa_attributes, wdpa_release.protected_areas
  end

  test '.clean_up removes the GDB and zip files, and drops the import tables' do
    zip_path = "zip_path"
    Wdpa::Release.any_instance.expects(:zip_path).returns(zip_path).at_least_once
    gdb_path = "gdb_path"
    Wdpa::Release.any_instance.expects(:gdb_path).returns(gdb_path).at_least_once
    geometry_tables = ["wdpa_poly", "wdpa_point"]
    Wdpa::Release.any_instance.expects(:geometry_tables).returns(geometry_tables)
    source_table = "wdpa_source"
    Wdpa::Release.any_instance.expects(:source_table).returns(source_table)

    FileUtils.expects(:rm_rf).with(zip_path)
    FileUtils.expects(:rm_rf).with(gdb_path)

    ActiveRecord::Migration.expects(:drop_table).with(geometry_tables[0])
    ActiveRecord::Migration.expects(:drop_table).with(geometry_tables[1])
    ActiveRecord::Migration.expects(:drop_table).with(source_table)

    wdpa_release = Wdpa::Release.new
    wdpa_release.clean_up
  end
end
