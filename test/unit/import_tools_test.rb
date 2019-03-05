require 'test_helper'

class ImportToolsTest < ActiveSupport::TestCase
  test '#create_import creates a new instance of ImportTools::Import' do
    ImportTools::Import.expects(:new)
    ImportTools.create_import
  end

  test '#current_import returns an Import with the token returned from Redis' do
    ImportTools::RedisHandler.any_instance.stubs(:current_token).returns(123)
    ImportTools::Import.expects(:new).with(123)

    ImportTools.current_import
  end

  test '#current_import returns nil if no import is found' do
    ImportTools::RedisHandler.any_instance.stubs(:current_token).returns(nil)

    assert_nil ImportTools.current_import
  end

  test '#last_import returns an instance of Import with the token of the last import' do
    ImportTools::RedisHandler.any_instance.expects(:previous_imports).returns([1, 2, 3])
    ImportTools::Import.expects(:new).with(3)

    ImportTools.last_import
  end
end
