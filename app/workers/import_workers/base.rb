class ImportWorkers::Base
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => :import, :backtrace => true

  singleton_class.send(:alias_method, :original_perform_async, :perform_async)

  def perform
    raise NotImplementedError
  end

  def finalise_job
    import = ImportTools.current_import
    import.increase_completed_jobs_count

    if import.completed? && ImportWorkers::FinaliserWorker.can_be_started
      # finalising process is being fuzzy. Let's notify
      # via bystander and call FinaliserWorker manually
      # ImportWorkers::FinaliserWorker.perform_async
      Bystander.log("FinaliserWorker ready to be called")
    end
  end

  def self.perform_async *args
    import = ImportTools.current_import
    import.increase_total_jobs_count

    original_perform_async(*args)
  end
end
