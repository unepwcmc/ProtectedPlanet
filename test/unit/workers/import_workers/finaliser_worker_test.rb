require 'test_helper'

class ImportWorkersFinaliserWorkerTest < ActiveSupport::TestCase
  test '.perform calls finalise on the current import' do
    import_mock = mock()
    import_mock.expects(:finalise)
    ImportTools.stubs(:current_import).returns(import_mock)

    Search::Index.stubs(:delete)
    Search::Index.stubs(:create)
    Download.stubs(:make_current)
    ImportTools::WebHandler.stubs(:clear_cache)
    ImportTools::WebHandler.stubs(:under_maintenance).yields
    Geospatial::Calculator.stubs(:calculate_statistics)

    ImportWorkers::FinaliserWorker.new.perform
  end

  test '.perform executes commands under maintenance mode' do
    ImportTools::WebHandler.expects(:under_maintenance)
    ImportWorkers::FinaliserWorker.new.perform
  end

  test '.perform refreshes cache, search index, updates S3 downloads and
   calculates statistics' do
    ImportTools.stubs(:current_import).returns(stub_everything)
    ImportTools::WebHandler.stubs(:under_maintenance).yields

    Search::Index.stubs(:delete)
    Search::Index.expects(:create)
    Download.expects(:make_current)
    ImportTools::WebHandler.expects(:clear_cache)
    Geospatial::Calculator.expects(:calculate_statistics)

    ImportWorkers::FinaliserWorker.new.perform
  end
end
