require 'test_helper'

class ImportToolsImportTest < ActiveSupport::TestCase
  test '#new tries to lock the import' do
    ImportTools::Import.any_instance.stubs(:create_db)
    ImportTools::Import.any_instance.stubs(:use_import_db=)
    ImportTools::Import.any_instance.expects(:lock_import)

    ImportTools::Import.new
  end

  test '#new raises an exception if the lock fails' do
    ImportTools::Import.any_instance.expects(:create_db).never
    ImportTools::RedisHandler.any_instance.stubs(:lock).returns(false)

    assert_raise ImportTools::AlreadyRunningImportError do
      ImportTools::Import.new
    end
  end

  test '#new creates and seeds a DB with the given name' do
    ImportTools::Import.any_instance.stubs(:lock_import)
    ImportTools::Import.any_instance.expects(:create_db)
    ImportTools::Import.any_instance.stubs(:use_import_db=)

    ImportTools::Import.new
  end

  test '.started_at returns a Time instance created from the import token (timestamp)' do
    import_starting_time = Time.new(2014, 1, 1)
    token = import_starting_time.to_i
    import = ImportTools::Import.new(token)

    assert_equal import_starting_time, import.started_at
  end

  test '.increase_total_jobs_count calls redis to increase the number of jobs' do
    token = 123
    ImportTools::RedisHandler.any_instance.expects(:increase_property)

    import = ImportTools::Import.new(token)
    import.increase_total_jobs_count
  end

  test '.increase_completed_jobs_count sets the completed property for the import' do
    ImportTools::RedisHandler.any_instance.expects(:increase_property_and_compare).returns(true)

    import = ImportTools::Import.new(123)
    import.increase_completed_jobs_count

    assert import.completed?
  end

  test '.stop(true) drops the old db and renames the new one' do
    import = ImportTools::Import.new(123)

    test_db = Rails.configuration.database_configuration[Rails.env]['database']
    import_db = "import_db_#{import.token}"

    ImportTools::PostgresHandler.any_instance.expects(:drop_database).with(test_db)
    ImportTools::PostgresHandler.any_instance.expects(:rename_database).with(import_db, test_db)

    import.stop
  end

  test '.stop(true) unlocks the import' do
    import = ImportTools::Import.new(123)

    ImportTools::PostgresHandler.stubs(:new).returns(stub_everything)
    ImportTools::RedisHandler.any_instance.expects(:unlock)

    import.stop
  end

  test '.stop(true) adds the import to the done imports' do
    import = ImportTools::Import.new(123)

    ImportTools::PostgresHandler.stubs(:new).returns(stub_everything)
    ImportTools::RedisHandler.any_instance.expects(:add_to_previous_imports).with(123)

    import.stop
  end

  test '.stop(false) unlocks the import, but does not swap the databases' do
    import = ImportTools::Import.new(123)

    ImportTools::PostgresHandler.any_instance.expects(:drop_database).never
    ImportTools::PostgresHandler.any_instance.expects(:rename_database).never

    ImportTools::PostgresHandler.stubs(:new).returns(stub_everything)
    ImportTools::RedisHandler.any_instance.expects(:unlock)

    import.stop
  end

  test '.stop(false) adds the import to the done imports, but does not
   swap the databases' do
    import = ImportTools::Import.new(123)

    ImportTools::PostgresHandler.any_instance.expects(:drop_database).never
    ImportTools::PostgresHandler.any_instance.expects(:rename_database).never

    ImportTools::PostgresHandler.stubs(:new).returns(stub_everything)
    ImportTools::RedisHandler.any_instance.expects(:add_to_previous_imports).with(123)

    import.stop
  end
end
