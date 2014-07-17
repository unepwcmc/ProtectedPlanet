require 'test_helper'

class ImportToolsTest < ActiveSupport::TestCase
  test '#create_import creates a new instance of ImportTools::Import' do
    ImportTools::Import.expects(:new)
    ImportTools.create_import
  end

  test '#current_import returns an Import with the id returned from Redis' do
    ImportTools::RedisHandler.any_instance.stubs(:current_import_id).returns(123)

    import = ImportTools.current_import
    assert_equal 123, import.id
  end

  test '#current_import returns nil if no import is found' do
    ImportTools::RedisHandler.any_instance.stubs(:current_import_id).returns(nil)

    import = ImportTools.current_import
    assert_equal nil, import
  end
end
