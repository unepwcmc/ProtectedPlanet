require 'test_helper'

class WdpaImportWorkerTest < ActiveSupport::TestCase
  test '.perform stops immediately if there is another import ongoing' do
    ImportTools.stubs(:create_import).returns(false)
    Wdpa::Importer.expects(:import).never

    Sidekiq::Testing.inline! { WdpaImportWorker.perform_async }
  end

  test '.perform calls the WdpaImporter and unlocks redis after the process' do
    ImportTools.stubs(:create_import).returns(true)
    Wdpa::Importer.expects(:import)

    Sidekiq::Testing.inline! { WdpaImportWorker.perform_async }
  end
end
