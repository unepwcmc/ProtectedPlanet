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

    connection_mock = mock()
    connection_mock.expects(:execute)
    ImportTools::PostgresHandler.any_instance.stubs(:close_connections_to)
    ImportTools::PostgresHandler.any_instance.stubs(:connect_to).returns(connection_mock)

    pg_handler = ImportTools::PostgresHandler.new
    pg_handler.rename_database db_name, new_db_name
  end

  test '.seed invokes the db:seed rake task' do
    Rake::Task.expects(:[]).with('db:seed').returns(mock.tap { |m|
      m.expects(:invoke)
    })

    pg_handler = ImportTools::PostgresHandler.new
    pg_handler.seed
  end
end
