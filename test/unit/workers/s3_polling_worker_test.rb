require 'test_helper'

class S3PollingWorkerTest < ActiveSupport::TestCase
  test '.perform calls S3.new_wdpa? to look for a new release, and spawns
   WdpaImportWorker, if a new release is found' do
    last_import_md5 = '123abc'
    last_import_at = Time.now.to_i

    Sidekiq.expects(:redis).yields(stub_everything()).returns([last_import_md5, last_import_at])
    Wdpa::S3.expects(:new_wdpa?).with(last_import_at).returns(true)
    WdpaImportWorker.expects(:perform_async)

    Sidekiq::Testing.inline! do
      S3PollingWorker.perform_async
    end
  end


end
