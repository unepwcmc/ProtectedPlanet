require 'test_helper'

class ImportConfirmationTest < ActionDispatch::IntegrationTest
  test '/admin/import/<token>/confirm returns a 401 if no key is given' do
    get '/admin/import/123/confirm'
    assert_response 401
  end

  test '/import/<token>/confirm returns a 200 if no key is given' do
    skip
  end

  test '/import/<token>/confirm returns a 200 if a valid key and token
   is given' do
    skip
  end
end
