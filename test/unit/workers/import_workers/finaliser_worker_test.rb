require 'test_helper'

class ImportWorkersFinaliserWorkerTest < ActiveSupport::TestCase
  test '.perform calls finalise on the current import' do
    import_mock = mock()
    import_mock.expects(:finalise)
    ImportTools.stubs(:current_import).returns(import_mock)

    ImportWorkers::FinaliserWorker.new.perform
  end
end
