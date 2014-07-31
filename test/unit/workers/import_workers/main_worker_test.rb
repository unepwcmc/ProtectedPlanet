require 'test_helper'

class ImportWorkersMainWorkerTest < ActiveSupport::TestCase
  test '.perform calls the ImportWorkers::MainWorker and unlocks redis after the process' do
    import_mock = mock()
    import_mock.stubs(:with_context).yields
    ImportTools.stubs(:current_import).returns(import_mock)

    Wdpa::Importer.expects(:import)

    ImportWorker.any_instance.stubs(:finalise_job)
    ImportWorkers::MainWorker.new.perform
  end
end
