require 'test_helper'

class ImportToolsRedisHandlerTest < ActiveSupport::TestCase
  def setup
    @redis_handler = ImportTools::RedisHandler.new
  end

  test '.new sets the redis instance variable' do
    assert_not_nil @redis_handler.redis
  end

  test '.lock_import calls the setnx redis command with the given arguments' do
    current_import_key = 'test_key'
    @redis_handler.stubs(:current_import_key).returns(current_import_key)

    value = 'test_value'
    @redis_handler.redis.expects(:setnx).with(current_import_key, value)

    @redis_handler.lock(value)
  end

  test '.current_import_id gets the id of the current import from redis' do
    expected_key = "#{Rails.application.secrets.redis['wdpa_imports_prefix']}:current_import"

    @redis_handler.redis.expects(:get).with(expected_key)
    @redis_handler.current_import_id
  end
end
