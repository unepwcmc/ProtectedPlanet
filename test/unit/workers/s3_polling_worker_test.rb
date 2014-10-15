require 'test_helper'

class S3PollingWorkerTest < ActiveSupport::TestCase
  test '.perform calls S3.new_wdpa? to look for a new release, and spawns
   MainWorker, if a new release is found' do
    last_import_started_at = Time.now

    import_mock = mock()
    import_mock.stubs(:token).returns(last_import_started_at.to_s)
    import_mock.stubs(:started_at).returns(last_import_started_at)
    ImportTools.stubs(:last_import).returns(import_mock)
    ImportTools.stubs(:create_import)

    Wdpa::S3.expects(:new_wdpa?).with(last_import_started_at).returns(true)

    ImportConfirmationMailer.expects(:create).with(import_mock)

    Sidekiq::Testing.inline! do
      S3PollingWorker.perform_async
    end
  end

  test '.perform stops immediately if there is another import ongoing' do
    Wdpa::S3.stubs(:new_wdpa?).returns(true)
    ImportTools.stubs(:create_import).raises(ImportTools::AlreadyRunningImportError)
    ImportWorkers::MainWorker.expects(:perform_async).never

    Sidekiq::Testing.inline! { S3PollingWorker.perform_async }
  end

end
