require 'test_helper'

class ImportToolsRedisHandlerTest < ActiveSupport::TestCase
  def setup
    @redis_handler = ImportTools::RedisHandler.new
  end

  test '.lock calls the setnx redis command with the given arguments' do
    current_key = 'test_key'
    @redis_handler.stubs(:current_key).returns(current_key)

    value = 'test_value'
    $redis.expects(:setnx).with(current_key, value)

    @redis_handler.lock(value)
  end

  test '.unlock calls the setnx redis command with the given arguments' do
    current_key = 'test_key'
    @redis_handler.stubs(:current_key).returns(current_key)
    $redis.expects(:del).with(current_key)

    @redis_handler.unlock
  end

  test '.current_token gets the token of the current import from redis' do
    expected_key = "#{Rails.application.secrets.redis['wdpa_imports_prefix']}:current"

    $redis.expects(:get).with(expected_key)
    @redis_handler.current_token
  end

  test '.increase_property_and_compare calls redis commands in a redis transaction' do
    $redis.expects(:multi).yields.returns([])
    @redis_handler.increase_property_and_compare(123, :test_key_1, :test_key_2)
  end

  test '.increase_property_and_compare returns true if the values for the properties are equal' do
    token = 1
    key_1, key_2 = [:key_1, :key_2]
    value_1, value_2 = [123, 123]

    $redis.stubs(:multi).returns([value_1, value_2])

    assert @redis_handler.increase_property_and_compare(token, key_1, key_2)
  end

  test '.add_to_previous_imports calls redis zadd with the given token' do
    token = 123
    $redis.expects(:zadd).with(anything, token, token.to_s)

    @redis_handler.add_to_previous_imports(token)
  end
end
