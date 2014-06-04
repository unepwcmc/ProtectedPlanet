require 'test_helper'

class TestOgrPostgres < ActiveSupport::TestCase
  test '.import runs the correct ogr2ogr command to import a geo
   database to postgres' do
    db_config = Rails.configuration.database_configuration[Rails.env]
    db_name   = "my_little_database"

    ogr_command = "ogr2ogr -overwrite -skipfailures -lco ENCODING=UTF-8 -f \"PostgreSQL\" PG:\" host=#{db_config["host"]} user=#{db_config["username"]} dbname=#{db_name}\" ./an/file"
    Ogr::Postgres.any_instance.expects(:system).with(ogr_command).once

    ogr = Ogr::Postgres.new
    ogr.import file: './an/file', to: db_name
  end

  test '.import defaults to the database in the Rails config if no
   database is given' do
    db_config = Rails.configuration.database_configuration[Rails.env]

    ogr_command = "ogr2ogr -overwrite -skipfailures -lco ENCODING=UTF-8 -f \"PostgreSQL\" PG:\" host=#{db_config["host"]} user=#{db_config["username"]} dbname=#{db_config["database"]}\" ./an/file"
    Ogr::Postgres.any_instance.expects(:system).with(ogr_command).once

    ogr = Ogr::Postgres.new
    ogr.import file: './an/file'
  end
end
