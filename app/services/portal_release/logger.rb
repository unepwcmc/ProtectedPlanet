# frozen_string_literal: true

require 'fileutils'

module PortalRelease
  class Logger
    def initialize(release)
      @release = release
      @label   = release.label
      @file_logger = build_file_logger
    end

    # Generic event logger. Persists to DB, app log, and dedicated JSON log.
    #
    # event_name - short string (e.g., 'staging_prepared', 'swap_completed')
    # payload    - additional context to merge into the JSON log line
    # phase      - optional current phase name (string/symbol)
    def event(event_name, payload: {}, phase: nil)
      ts = Time.current

      # DB audit trail
      ReleaseEvent.create!(release: @release, phase: event_name.to_s, payload_json: payload, at: ts)

      # Structured payload used for app log and dedicated log
      json = {
        ts: ts.iso8601(6),
        level: 'info',
        event: event_name.to_s,
        phase: phase&.to_s,
        release_id: @release.id,
        label: @label
      }.merge(payload.transform_keys(&:to_sym))

      # Application log (stdout in docker)
      Rails.logger.info(json.to_json)
      # Dedicated portal release JSON log
      @file_logger&.info(json.to_json)
    end

    # Emit a phase started marker
    def phase_started(phase)
      event('phase_started', payload: {}, phase: phase)
    end

    # Emit a phase completed marker with duration
    def phase_completed(phase, duration:)
      event('phase_completed', payload: { seconds: duration.round(2) }, phase: phase)
    end

    # Emit an error entry with exception info
    def error(e, phase:, extra: {})
      ts = Time.current
      json = {
        ts: ts.iso8601(6),
        level: 'error',
        event: 'exception',
        phase: phase&.to_s,
        release_id: @release.id,
        label: @label,
        error_class: e.class.name,
        error_message: e.message,
        backtrace: Array(e.backtrace)&.first(20)
      }.merge(extra.transform_keys(&:to_sym))

      Rails.logger.error(json.to_json)
      @file_logger&.error(json.to_json)

      # Also persist a DB event for errors
      ReleaseEvent.create!(release: @release, phase: 'exception', payload_json: json, at: ts)
    end

    # Backward-compatible metric emitter; still emits as a dedicated event
    def metric(phase, duration:)
      event('phase_duration', payload: { phase: phase.to_s, seconds: duration.round(2) }, phase: phase)
    end

    private

    def build_file_logger
      path = ENV['PP_RELEASE_LOG_PATH'].presence || Rails.root.join('log', 'portal_release.log')
      FileUtils.mkdir_p(File.dirname(path))
      logger = ActiveSupport::Logger.new(path)
      # Formatter returns raw message (already JSON) with newline
      logger.formatter = proc { |_severity, _datetime, _progname, msg| "#{msg}\n" }
      logger.level = ::Logger::INFO
      logger
    rescue StandardError => e
      Rails.logger.warn("PortalRelease::Logger file logger init failed: #{e.class}: #{e.message}")
      nil
    end
  end
end

