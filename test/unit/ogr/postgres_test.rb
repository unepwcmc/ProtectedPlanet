require 'test_helper'

class TestOgrPostgres < ActiveSupport::TestCase
  test '.import runs the correct ogr2ogr command to import a geo
   database to postgres' do
    db_config = Rails.configuration.database_configuration[Rails.env]

    ogr_command = "ogr2ogr -overwrite -skipfailures -lco ENCODING=UTF-8 -f \"PostgreSQL\" PG:\" host=#{db_config["host"]} user=#{db_config["username"]} dbname=#{db_config["database"]}\" ./an/file"
    Ogr::Postgres.any_instance.expects(:system).with(ogr_command).once

    Ogr::Postgres.import './an/file'
  end

  test '.import imports a specific table when specified' do
    table_name = "my_first_table"
    db_config = Rails.configuration.database_configuration[Rails.env]

    ogr_command = """
      ogr2ogr -overwrite -skipfailures -lco ENCODING=UTF-8
      -f \"PostgreSQL\" PG:\" host=#{db_config["host"]}
      user=#{db_config["username"]} dbname=#{db_config["database"]}\"
      -sql \"SELECT * FROM #{table_name}\"
      ./an/file
    """.squish
    Ogr::Postgres.any_instance.expects(:system).with(ogr_command).once

    Ogr::Postgres.import './an/file', table_name
  end

  test '.import imports a given table to a specific new table when
   specified' do
    table_name = "my_first_table"
    new_table_name = "my_second_first_table"
    db_config = Rails.configuration.database_configuration[Rails.env]

    ogr_command = """
      ogr2ogr -overwrite -skipfailures -lco ENCODING=UTF-8
      -f \"PostgreSQL\" PG:\" host=#{db_config["host"]}
      user=#{db_config["username"]} dbname=#{db_config["database"]}\"
      -sql \"SELECT * FROM #{table_name}\"
      -nln #{new_table_name}
      ./an/file
    """.squish
    Ogr::Postgres.any_instance.expects(:system).with(ogr_command).once

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
end
