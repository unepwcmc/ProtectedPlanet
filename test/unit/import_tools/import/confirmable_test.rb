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

  test '.verify_confirmation_key, given a valid confirmation key,
   returns true' do
    confirmation_key = "abcd123"

    import = ImportTools::Import.new('abcd')

    ImportTools::RedisHandler.any_instance.
      expects(:get_property).
      with(import.token, 'confirmation_key').
      returns(confirmation_key)

    assert import.verify_confirmation_key(confirmation_key),
      "Expected the confirmation key #{confirmation_key} to be correct"
  end

  test '.verify_confirmation_key, given an invalid confirmation key,
   returns false' do
    confirmation_key = "abcd123"

    import = ImportTools::Import.new('abcd')

    ImportTools::RedisHandler.any_instance.
      expects(:get_property).
      with(import.token, 'confirmation_key').
      returns("cbda321")

    refute import.verify_confirmation_key(confirmation_key),
      "Expected the confirmation key #{confirmation_key} to not be correct"
  end

  test '.verify_confirmation_key, given nil, returns false' do
    import = ImportTools::Import.new('abcd')

    refute import.verify_confirmation_key(nil),
      "Expected nil to not be verifiable"
  end
end
