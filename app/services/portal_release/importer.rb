# frozen_string_literal: true

module PortalRelease
  class Importer
    def initialize(log, label:, release_id: nil, notifier: nil)
      @log = log
      @label = label
      @release_id = release_id
      @notifier = notifier
    end

    def run_core!
      @log.event('import_core_started')

      # Step 2 orchestrator handles all staging imports and returns a result hash
      # Wire through runtime flags for importer filtering and checkpoints
      import_only = ENV.fetch('PP_IMPORT_ONLY', nil)
      import_skip = ENV.fetch('PP_IMPORT_SKIP', nil)
      import_sample = ENV.fetch('PP_IMPORT_SAMPLE', nil)

      results = Wdpa::Portal::Importer.import(
        create_staging_materialized_views: false,
        only: import_only,
        skip: import_skip,
        sample: import_sample,
        label: @label,
        release_id: @release_id,
        notifier: @notifier
      )

      @log.event('import_core_finished', payload: { success: results[:success], hard_errors: results[:hard_errors] })

      raise "Importer reported hard errors: #{Array(results[:hard_errors]).join('; ')}" unless results[:success]

      results
    end
  end
end
