# frozen_string_literal: true

module PortalRelease
  class Service
    PHASES = %i[
      acquire_lock
      create_staging_materialized_views
      preflight
      build_staging
      import_core
      import_related
      validate_and_manifest
      finalise_swap
      create_portal_downloads_view
      post_swap
      cleanup_and_retention
      release_lock
      reset_checkpoints
    ].freeze

    def self.abort_current!
      # Release the lock first to allow new releases to start
      begin
        Lock.new.release!(Rails.logger)
        Rails.logger.info('Lock released during abort')
      rescue StandardError => e
        Rails.logger.warn("Failed to release lock during abort: #{e.message}")
      end
      
      # Minimal abort: drop staging tables to leave clean state
      Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
      Rails.logger.warn('Aborted current release; staging tables dropped and lock released')
      true
    end

    def self.rollback_to!(timestamp)
      SwapManager.new.rollback_to!(timestamp)
    end

    def self.status_report
      last = Release.order(created_at: :desc).first
      return 'No releases found' unless last

      {
        id: last.id,
        label: last.label,
        state: last.state,
        created_at: last.created_at,
        updated_at: last.updated_at,
        manifest_url: last.manifest_url
      }.to_json
    end

    def initialize(label:)
      @label = label
      @ctx   = {}

      begin
        validate_label_format!(@label)
        @release = Release.create!(label: label)
        @log     = ::PortalRelease::Logger.new(@release)
        @notify  = ::PortalRelease::Notifier.new(@release)
      rescue ActiveRecord::RecordInvalid => e
        # Send error notification even without a release record
        @notify = ::PortalRelease::Notifier.new(label)
        @notify.error(e, phase: 'initialisation')
        raise
      end
    end

    def run!
      phases = PHASES
      start_at = (ENV['PP_RELEASE_START_AT'] || ENV.fetch('PP_RELEASE_SKIP_TO', nil)).to_s.strip
      stop_after = (ENV['PP_RELEASE_STOP_AFTER'] || ENV.fetch('PP_RELEASE_SKIP_AFTER', nil)).to_s.strip
      only_phases = (ENV['PP_RELEASE_ONLY_PHASES'] || '').split(',').map(&:strip).reject(&:empty?)

      phases = phases.select { |p| only_phases.include?(p.to_s) } unless only_phases.empty?
      phases = phases.drop_while { |p| !start_at.empty? && p.to_s != start_at } unless start_at.empty?

      phases.each do |phase|
        # Stop before starting phases after validate_and_manifest if dry run is enabled
        if ActiveModel::Type::Boolean.new.cast(ENV.fetch('PP_RELEASE_DRY_RUN', nil))
          # Check if we've already completed validate_and_manifest and are about to start a later phase
          validate_and_manifest_index = phases.index(:validate_and_manifest)
          current_index = phases.index(phase)
          if validate_and_manifest_index && current_index && current_index > validate_and_manifest_index
            @log.event('dry_run_stopped_after_validate_and_manifest')
            @notify.phase('Dry run stopped after validate_and_manifest phase')
            break
          end
        end
        
        @ctx[:phase] = phase.to_s
        @log.phase_started(@ctx[:phase])
        duration = time { send(phase) }
        @log.phase_completed(@ctx[:phase], duration: duration)
        @notify.phase_complete(@ctx[:phase], duration_s: duration)
        
        break if !stop_after.empty? && phase.to_s == stop_after
      end

      true
    rescue StandardError => e
      @release.update!(state: 'failed', error_text: "#{e.class}: #{e.message}")
      @log.error(e, phase: @ctx[:phase], extra: { where: 'service.run' })
      @notify.error(e, phase: @ctx[:phase])
      # Best-effort staging cleanup on failure
      begin
        Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
      rescue StandardError => cleanup_err
        Rails.logger.warn("Staging cleanup on failure failed: #{cleanup_err.class}: #{cleanup_err.message}")
      end
      raise
    ensure
      release_lock
    end

    private

    # Only "MMMYYYY" is allowed
    # NOTE: This regex only matches English month abbreviations (Jan, Feb, Mar, etc.).
    #       If other locales are required, update this validation accordingly.
    LABEL_REGEX = /\A[A-Z][a-z]{2}\d{4}\z/.freeze

    def validate_label_format!(label)
      return if LABEL_REGEX.match?(label.to_s)

      raise ArgumentError,
        "Invalid release label '#{label}'. Expected format MMMYYYY with English month abbreviation (e.g., Jan2025, Feb2025)."
    end

    # Yields to the phase block and returns duration in seconds
    def time
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      @log.metric(@ctx[:phase], duration: duration)
      duration
    end

    def acquire_lock
      @ctx[:phase] = 'acquire_lock'
      Lock.new.acquire!(@release, @log, @notify)
    end

    def create_staging_materialized_views
      @ctx[:phase] = 'create_staging_materialized_views'
      Preflight.create_staging_mvs!(@log)
    end

    def preflight
      @ctx[:phase] = 'preflight'
      Preflight.run!(@release, @log, @notify, @ctx)
    end

    def create_portal_downloads_view
      @ctx[:phase] = 'create_portal_downloads_view'
      Preflight.create_portal_downloads_view!(@log)
    end

    def build_staging
      @ctx[:phase] = 'build_staging'
      PortalRelease::Staging.new(@log).prepare!
    end

    def import_core
      @ctx[:phase] = 'import_core'
      results = Importer.new(@log, label: @label, release_id: @release.id, notifier: @notify).run_core!
      @release.update!(state: 'importing', stats_json: (@release.stats_json || {}).merge({ importer: results }))
      # Human-readable Slack summary for core import
      @notify.import_core_summary(results) if results.respond_to?(:each)
    end

    def import_related
      @ctx[:phase] = 'import_related'
      RelatedImporters.new(@log).run_all!
    end

    def validate_and_manifest
      @ctx[:phase] = 'validate_and_manifest'
      Validate.new(@release, @log).run!
      Manifest.new(@release, @log).write!
    end

    def finalise_swap
      @ctx[:phase] = 'finalise_swap'
      SwapManager.new.finalise!(release: @release, log: @log, notify: @notify)
      @release.update!(state: 'swapped')
    end

    def post_swap
      @ctx[:phase] = 'post_swap'
      Cleanup.post_swap!(@log, notifier: @notify)
    end

    def cleanup_and_retention
      @ctx[:phase] = 'cleanup'
      Cleanup.retention!(@log)
      @release.update!(state: 'succeeded')
      @notify.success
    end

    def release_lock
      Lock.new.release!(@log)
    end

    def reset_checkpoints
      @ctx[:phase] = 'reset_checkpoints'
      Wdpa::Portal::Checkpoint.reset_all!
    end
  end
end
