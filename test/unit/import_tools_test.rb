require 'test_helper'

class ImportToolsTest < ActiveSupport::TestCase
  test '#with_db creates a DB with the given name' do
    db_name = 'temp_test_db'

    ImportTools::PostgresHandler.any_instance.expects(:create_database).with(db_name)
    ImportTools::PostgresHandler.any_instance.stubs(:with_db)

    ImportTools.with_db(db_name) {}
  end

  test '#with_db creates a context with a different DB using PostgresHandler' do
    db_name = 'temp_test_db'

    ImportTools::PostgresHandler.any_instance.stubs(:create_database)
    ImportTools::PostgresHandler.any_instance.expects(:with_db).with(db_name)

    ImportTools.with_db(db_name) {}
  end
end
