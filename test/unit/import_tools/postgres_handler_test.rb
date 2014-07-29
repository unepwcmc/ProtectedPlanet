require 'test_helper'

class ImportToolsPostgresHandlerTest < ActiveSupport::TestCase
  test '#new sets the current_conn_values properly' do
    db_hash = {'database' => 'test_db'}
    ActiveRecord::Base.configurations.expects(:[]).with(Rails.env).returns(db_hash)

    pg_handler = ImportTools::PostgresHandler.new

    assert_equal db_hash, pg_handler.current_conn_values
  end

  test '.create_database creates a new db with the given name' do
    db_name = 'temp_test_db'
    ActiveRecord::Base.stubs(:establish_connection)
    ActiveRecord::Base.connection.expects(:create_database).with(db_name)

    pg_handler = ImportTools::PostgresHandler.new
    pg_handler.create_database db_name
  end

  test '.drop_database drops a db with the given name' do
    db_name = 'temp_test_db'
    ActiveRecord::Base.stubs(:establish_connection)
    ActiveRecord::Base.connection.expects(:drop_database).with(db_name)

    pg_handler = ImportTools::PostgresHandler.new
    pg_handler.drop_database db_name
  end

  test '.rename_database executes a query to rename the db' do
    db_name, new_db_name = 'db', 'new_db'
    expected_query = "ALTER DATABASE #{db_name} RENAME TO #{new_db_name}"

    ActiveRecord::Base.stubs(:establish_connection)
    ActiveRecord::Base.connection.expects(:execute)
    ActiveRecord::Base.connection.expects(:execute).with(expected_query)

    pg_handler = ImportTools::PostgresHandler.new
    pg_handler.rename_database db_name, new_db_name
  end

  test '.seed populates the given db via an external command' do
    test_db_name = 'test_db'
    dump_path = './test/path.sql'
    db_config = {
      'username' => 'test',
      'password' => 'test_pwd',
      'database' => 'config_db',
      'host'     => 'host'
    }
    ActiveRecord::Base.configurations.stubs(:[]).returns(db_config)

    command = """
      PGPASSWORD=#{db_config['password']}
      psql -d #{test_db_name} -U #{db_config['username']} -h #{db_config['host']} < #{dump_path.to_s}
    """.squish
    ImportTools::PostgresHandler.any_instance.expects(:system).with(command)

    pg_handler = ImportTools::PostgresHandler.new
    pg_handler.seed(test_db_name, dump_path)
  end
end
