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

  test '.properties creates and returns a ActiveToken::Properties object with
   the token key' do
    properties = {'prop1' => 'value1'}
    obj = TestObj.new
    obj.token = '123'

    ActiveToken::Properties
      .expects(:new)
      .with(TestObj.token_key(obj.token))
      .returns(properties)
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
