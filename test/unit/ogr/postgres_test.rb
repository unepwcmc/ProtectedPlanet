require 'test_helper'

class TestOgrPostgres < ActiveSupport::TestCase
  test '.import runs the correct ogr2ogr command to import a geo
   database to postgres' do
    db_config = ActiveRecord::Base.connection_config

    ogr_command = "ogr2ogr -overwrite -skipfailures -lco ENCODING=UTF-8 --config PG_USE_COPY YES -f \"PostgreSQL\" PG:\" host=#{db_config[:host]} user=#{db_config[:username]}" + ( db_config[:password].nil? ? "": " password=#{db_config[:password]}") + " dbname=#{db_config[:database]}\" ./an/file"
    Ogr::Postgres.expects(:system).with(ogr_command).once

    Ogr::Postgres.import './an/file'
  end

  test '.import imports a specific table when specified' do
    table_name = "my_first_table"
    db_config = ActiveRecord::Base.connection_config

    ogr_command = "ogr2ogr -overwrite -skipfailures -lco ENCODING=UTF-8 --config PG_USE_COPY YES -f \"PostgreSQL\" PG:\" host=#{db_config[:host]} user=#{db_config[:username]}" + ( db_config[:password].nil? ? "": " password=#{db_config[:password]}") + " dbname=#{db_config[:database]}\" -sql \"SELECT * FROM #{table_name}\" ./an/file"
    Ogr::Postgres.expects(:system).with(ogr_command).once

    Ogr::Postgres.import './an/file', table_name
  end

  test '.import imports a given table to a specific new table when
   specified' do
    table_name = "my_first_table"
    new_table_name = "my_second_first_table"
    db_config = ActiveRecord::Base.connection_config

    ogr_command = "ogr2ogr -overwrite -skipfailures -lco ENCODING=UTF-8 --config PG_USE_COPY YES -f \"PostgreSQL\" PG:\" host=#{db_config[:host]} user=#{db_config[:username]}" + ( db_config[:password].nil? ? "": " password=#{db_config[:password]}") + " dbname=#{db_config[:database]}\" -sql \"SELECT * FROM #{table_name}\" -nln #{new_table_name} ./an/file"
    Ogr::Postgres.expects(:system).with(ogr_command).once

    Ogr::Postgres.import './an/file', table_name, new_table_name
  end

  test '.import raises an error if given a new table name, but no
   original table name' do
    new_table_name = "my_second_first_table"
    error_msg = 'Given new table name, but no original table name'

    assert_raises ArgumentError, error_msg do
      Ogr::Postgres.import './an/file', nil, new_table_name
    end
  end

  test '.export given the Shapefile type, executes a ogr2ogr command
   that exports to a Shapefile with the given query' do
    db_config = ActiveRecord::Base.connection_config
    query = 'SELECT * FROM table'
    driver = 'ESRI Shapefile'
    export_file_name = 'export.shp'

    ogr_command = "ogr2ogr -skipfailures -f \"#{driver}\" #{export_file_name} PG:\"host=#{db_config[:host]} user=#{db_config[:username]}" + ( db_config[:password].nil? ? "": " password=#{db_config[:password]}") + " dbname=#{db_config[:database]}\" -sql \"#{query}\" -lco \"ENCODING=UTF-8\" -lco \"WRITE_BOM=YES\""

    Ogr::Postgres.expects(:system).with(ogr_command).once

    Ogr::Postgres.export :shapefile, export_file_name, query
  end

  test '.export given the CSV type, executes a ogr2ogr command
   that exports to a CSV with the given query' do
    db_config = ActiveRecord::Base.connection_config
    query = 'SELECT * FROM table'
    driver = 'CSV'
    export_file_name = 'export.csv'

    ogr_command = "ogr2ogr -skipfailures -f \"#{driver}\" #{export_file_name} PG:\"host=#{db_config[:host]} user=#{db_config[:username]}" + ( db_config[:password].nil? ? "": " password=#{db_config[:password]}") + " dbname=#{db_config[:database]}\" -sql \"#{query}\" -lco \"ENCODING=UTF-8\" -lco \"WRITE_BOM=YES\""

    Ogr::Postgres.expects(:system).with(ogr_command).once

    Ogr::Postgres.export :csv, export_file_name, query
  end
end
