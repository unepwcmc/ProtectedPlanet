require 'test_helper'

class WdpaImportWorkerTest < ActiveSupport::TestCase
  test '.perform stops immediately if there is another import ongoing' do
    ImportTools.stubs(:create_import).raises(ImportTools::AlreadyRunningImportError)
    Wdpa::Importer.expects(:import).never

    Sidekiq::Testing.inline! { WdpaImportWorker.perform_async }
  end

  test '.perform calls the WdpaImporter and unlocks redis after the process' do
    import_mock = mock()
    import_mock.stubs(:with_context).yields
    ImportTools.stubs(:create_import).returns(import_mock)

    Wdpa::Importer.expects(:import)

    Sidekiq::Testing.inline! { WdpaImportWorker.perform_async }
  end
end
