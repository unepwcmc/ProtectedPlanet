# frozen_string_literal: true

module PortalRelease
  class Importer
    def initialize(log, label:)
      @log = log
      @label = label
    end

    def run_core!
      @log.event('import_core_started')

      # Step 2 orchestrator handles all staging imports and returns a result hash
      # Wire through runtime flags for importer filtering and checkpoints
      import_only = ENV['PP_IMPORT_ONLY']
      import_skip = ENV['PP_IMPORT_SKIP']
      import_sample = ENV['PP_IMPORT_SAMPLE']

      results = Wdpa::Portal::Importer.import(
        refresh_materialized_views: false,
        only: import_only,
        skip: import_skip,
        sample: import_sample,
        label: @label
      )

      @log.event('import_core_finished', payload: { success: results[:success], hard_errors: results[:hard_errors] })

      unless results[:success]
        raise "Importer reported hard errors: #{Array(results[:hard_errors]).join('; ')}"
      end

      results
    end
  end
end

