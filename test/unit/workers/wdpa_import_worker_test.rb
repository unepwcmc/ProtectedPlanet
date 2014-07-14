require 'test_helper'

class WdpaImportWorkerTest < ActiveSupport::TestCase
  test '.perform stops immediately if there is another import ongoing' do
    Wdpa::Importer.expects(:import).never
    Sidekiq.expects(:redis).yields(stub_everything()).returns(nil)

    Sidekiq::Testing.inline! { WdpaImportWorker.perform_async }
  end

  test '.perform calls the WdpaImporter and unlocks redis after the process' do
    Wdpa::Importer.expects(:import)

    redis_mock = stub_everything()
    redis_mock.expects(:del)
    Sidekiq.expects(:redis).yields(redis_mock).returns(true).at_least_once

    Sidekiq::Testing.inline! { WdpaImportWorker.perform_async }
  end
end
