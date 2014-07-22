require 'test_helper'

class ImportToolsImportTest < ActiveSupport::TestCase
  test '#find returns an Import instance with the found ID' do
    id = 123
    import = ImportTools::Import.find(id)

    assert_kind_of ImportTools::Import, import
    assert_equal id, import.id
  end

  test '#new tries to lock the import' do
    ImportTools::Import.any_instance.stubs(:create_db)
    ImportTools::Import.any_instance.expects(:lock_import)

    ImportTools::Import.new
  end

  test '#new raises an exception if the lock fails' do
    ImportTools::Import.any_instance.stubs(:create_db)
    ImportTools::RedisHandler.any_instance.stubs(:lock).returns(false)

    assert_raise ImportTools::AlreadyRunningImportError do
      ImportTools::Import.new
    end
  end

  test '#new creates a DB with the given name' do
    ImportTools::Import.any_instance.stubs(:lock_import)
    ImportTools::Import.any_instance.expects(:create_db)

    ImportTools::Import.new
  end

  test '.with_context executes the block code using the temporary DB' do
    ImportTools::Import.any_instance.stubs(:create_db)
    ImportTools::Import.any_instance.stubs(:lock_import).returns(true)
    ImportTools::PostgresHandler.any_instance.expects(:with_db).yields

    import = ImportTools::Import.new
    import.with_context{}
  end

  test '.started_at returns a Time instance created from the import id (timestamp)' do
    import_starting_time = Time.new(2014, 1, 1)
    id = import_starting_time.to_i
    import = ImportTools::Import.new(id)

    assert_equal import_starting_time, import.started_at
  end

  test '.increase_total_jobs_count calls redis to increase the number of jobs' do
    id = 123
    ImportTools::RedisHandler.any_instance.expects(:increase_property)

    import = ImportTools::Import.new(id)
    import.increase_total_jobs_count
  end

  test '.increase_completed_jobs_count sets the completed property for the import' do
    id = 123
    ImportTools::RedisHandler.any_instance.expects(:increase_property_and_compare).returns(true)

    import = ImportTools::Import.new(id)
    import.increase_completed_jobs_count

    assert import.completed?
  end
end
