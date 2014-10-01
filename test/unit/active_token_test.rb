class ActiveTokenTest < ActiveSupport::TestCase
  class TestObj
    include ActiveToken
    token_domain 'test'
  end

  test '#find looks for a key on redis and initialises an instance with the
   containing attributes' do
    token = '123'
    $redis.expects(:exists).with("test:#{token}").returns(true)

    obj = TestObj.find token
    assert_equal token, obj.token
  end

  test '#create sets a key with the given token, and returns the created object' do
    token = '123'
    digested_token = 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'
    time_mock = mock.tap{ |time| time.stubs(:to_i).returns(1000) }

    Time.stubs(:now).returns(time_mock)
    $redis.expects(:hset).with("test:#{digested_token}", 'created_at', 1000)

    obj = TestObj.create token
    assert_kind_of TestObj, obj
  end

  test '.properties creates and returns a ActiveToken::Properties object with
   the token key' do
    properties = {'prop1' => 'value1'}
    obj = TestObj.new
    obj.token = '123'

    ActiveToken::Properties.
      expects(:new).
      with(TestObj.token_key(obj.token)).
      returns(properties)
    assert_equal properties, obj.properties
  end

  test '.generate_token generates a token using the given lambda or the default
   hex 10' do
    SecureRandom.expects(:hex).with(10).returns('12345abcde')
    assert_equal '12345abcde', ActiveToken.generate_token

    generator = -> { 2 + 2 }
    assert_equal '4', ActiveToken.generate_token(generator)
  end
end
