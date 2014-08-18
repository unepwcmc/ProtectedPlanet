require 'test_helper'

class ImportWorkersFinaliserWorkerTest < ActiveSupport::TestCase
  test '.perform calls finalise on the current import' do
    import_mock = mock()
    import_mock.expects(:finalise)
    ImportTools.stubs(:current_import).returns(import_mock)

    ImportTools::WebHandler.stubs(:clear_cache)
    ImportTools::WebHandler.stubs(:under_maintenance).yields

    ImportWorkers::FinaliserWorker.new.perform
  end

  test '.perform executes commands under maintenance mode' do
    ImportTools::WebHandler.expects(:under_maintenance)
    ImportWorkers::FinaliserWorker.new.perform
  end

  test '.perform refreshes cache and search index' do
    ImportTools.stubs(:current_import).returns(stub_everything)
    ImportTools::WebHandler.stubs(:under_maintenance).yields

    Search.expects(:reindex)
    ImportTools::WebHandler.expects(:clear_cache)

    ImportWorkers::FinaliserWorker.new.perform
  end
end
