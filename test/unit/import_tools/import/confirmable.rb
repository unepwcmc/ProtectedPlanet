require 'test_helper'

class ConfirmableTest < ActiveSupport::TestCase
  test '.confirmation_key generates a random secret and memoises it' do
    import = ImportTools::Import.new('abcd')
    generated_key = import.confirmation_key

    assert_equal 

    # Confirm the previously generated key is returned the second time
  end
end
