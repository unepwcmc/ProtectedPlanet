require 'test_helper'

class ImportWorkersMainWorkerTest < ActiveSupport::TestCase
  test '.perform starts the Wdpa Import' do
    Wdpa::Importer.expects(:import)

    ImportWorker.any_instance.stubs(:finalise_job)
    ImportWorkers::MainWorker.new.perform
  end
end
