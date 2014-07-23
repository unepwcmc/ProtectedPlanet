require 'test_helper'

class S3PollingWorkerTest < ActiveSupport::TestCase
  test '.perform calls S3.new_wdpa? to look for a new release, and spawns
   WdpaImportWorker, if a new release is found' do
    last_import_started_at = Time.now

    import_mock = mock()
    import_mock.stubs(:started_at).returns(last_import_started_at)
    ImportTools.stubs(:last_import).returns(import_mock)

    Wdpa::S3.expects(:new_wdpa?).with(last_import_started_at).returns(true)

    WdpaImportWorker.expects(:perform_async)

    Sidekiq::Testing.inline! do
      S3PollingWorker.perform_async
    end
  end


end
