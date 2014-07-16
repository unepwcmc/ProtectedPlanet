require 'test_helper'

class ImportToolsRedisHandlerTest < ActiveSupport::TestCase
  def setup
    @redis_handler = ImportTools::RedisHandler.new
  end

  test '.new sets the redis instance variable' do
    assert_not_nil @redis_handler.redis
  end

  test '.lock_import calls the setnx redis command with the given arguments' do
    locking_key = 'test_key'
    @redis_handler.stubs(:locking_key).returns(locking_key)

    value = 'test_value'
    @redis_handler.redis.expects(:setnx).with(locking_key, value)

    @redis_handler.lock(value)
  end
end
