require 'test_helper'

class ImportWorkersBaseTest < ActiveSupport::TestCase
  test '#perform_async increases the number of total tasks for the current import' do
    ImportWorkers::Base.any_instance.stubs(:perform)

    import_mock = mock()
    import_mock.expects(:increase_total_jobs_count)
    ImportTools.stubs(:current_import).returns(import_mock)

    ImportWorkers::Base.perform_async
  end

  test '.finalise_job increases the number of completed jobs for the current import' do
    import_mock = mock()
    import_mock.stubs(:completed?).returns(false)
    import_mock.expects(:increase_completed_jobs_count)

    ImportTools.stubs(:current_import).returns(import_mock)

    ImportWorkers::Base.new.finalise_job
  end
end
