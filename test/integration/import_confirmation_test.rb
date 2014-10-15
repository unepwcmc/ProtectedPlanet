require 'test_helper'

class ImportConfirmationTest < ActionDispatch::IntegrationTest
  test '/admin/import/<token>/confirm returns a 401 if no key is given' do
    import = ImportTools::Import.new('abcd')
    ImportTools::Import.stubs(:find).returns(import)

    get "/admin/import/#{import.token}/confirm"
    assert_response 401
  end

  test '/admin/import/<token>/confirm returns a 401 if an invalid key is
   given' do
    import = ImportTools::Import.new('abcd')
    ImportTools::Import.stubs(:find).returns(import)

    get "/admin/import/#{import.token}/confirm?key=fakekey"
    assert_response 401
  end

  test '/import/<token>/confirm returns a 200 if a valid key and token
   is given' do
    import = ImportTools::Import.new('abcd')
    ImportTools::Import.stubs(:find).returns(import)

    get "/admin/import/#{import.token}/confirm?key=#{import.confirmation_key}"
    assert_response 200
  end
end
