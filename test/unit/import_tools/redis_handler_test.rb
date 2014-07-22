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

  test '.increase_property_and_compare calls redis commands in a redis transaction' do
    @redis_handler.redis.expects(:multi).yields.returns([])
    @redis_handler.increase_property_and_compare(123, :test_key_1, :test_key_2)
  end

  test '.increase_property_and_compare returns true if the values for the properties are equal' do
    import_id = 1
    key_1, key_2 = [:key_1, :key_2]
    value_1, value_2 = [123, 123]

    @redis_handler.redis.stubs(:multi).returns([value_1, value_2])

    assert @redis_handler.increase_property_and_compare(import_id, key_1, key_2)
  end
end
