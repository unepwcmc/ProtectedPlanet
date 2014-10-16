require 'test_helper'

class Admin::ImportControllerTest < ActionController::TestCase
  test "GET :confirm, given a valid key, creates an Import worker to
   start the import process" do
    import = ImportTools::Import.new('abcd')
    ImportTools::Import.stubs(:find).returns(import)
    import.expects(:delete_confirmation_key)

    ImportWorkers::MainWorker.expects(:perform_async)

    get :confirm, import_id: import.token, key: import.confirmation_key

    assert_response :success
  end

  test "GET :cancel, given a valid key, stops the Import" do
    import = ImportTools::Import.new('abcd')
    ImportTools::Import.expects(:find).returns(import)
    import.expects(:stop).with(false)
    import.expects(:delete_confirmation_key)

    get :cancel, import_id: import.token, key: import.confirmation_key

    assert_response :success
  end

  test "GET :confirm, given an invalid key, does not delete the
   confirmation key" do
    import = ImportTools::Import.new('abcd')
    ImportTools::Import.expects(:find).returns(import)
    import.expects(:delete_confirmation_key).never

    get :cancel, import_id: import.token, key: "sdlknflfsdkn"

    assert_response 401
  end
end
