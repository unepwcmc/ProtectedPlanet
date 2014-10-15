require 'test_helper'

class ConfirmableTest < ActiveSupport::TestCase
  test '.confirmation_key generates a random secret and stores it in
   redis' do
    import = ImportTools::Import.new('abcd')

    confirmation_key = "abcd123"
    SecureRandom.expects(:hex).returns(confirmation_key)

    ImportTools::RedisHandler.any_instance.
      expects(:set_property).
      with(import.token, 'confirmation_key', confirmation_key)

    ImportTools::RedisHandler.any_instance.
      expects(:get_property).
      with(import.token, 'confirmation_key').
      returns(nil)

    generated_key = import.confirmation_key
    assert_equal confirmation_key, generated_key

    ImportTools::RedisHandler.any_instance.
      expects(:get_property).
      with(import.token, 'confirmation_key').
      returns(confirmation_key)

    # Confirm the previously generated key is returned the second time
    assert_equal generated_key, import.confirmation_key
  end
end
