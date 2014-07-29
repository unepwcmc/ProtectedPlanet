class ImportWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  singleton_class.send(:alias_method, :original_perform_async, :perform_async)

  def perform
    raise NotImplementedError
  end

  def finalise_job
    import = ImportTools.current_import
    import.increase_completed_jobs_count

    import.finalise if import.completed?
  end

  def self.perform_async *args
    begin
      import = ImportTools.current_import
      import.increase_total_jobs_count
    end

    original_perform_async *args
  end
end
