# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module PortalRelease
  class Notifier
    # Accepts a Release or a label string for ad-hoc notifications (e.g., rollback)
    def initialize(release_or_label)
      if defined?(Release) && release_or_label.is_a?(Release)
        @release = release_or_label
        @label   = @release.label
      else
        @release = nil
        @label   = release_or_label.to_s
      end
      @webhook = ENV['PP_SLACK_WEBHOOK_URL']
    end

    def started(label)
      # Just to make a seperator on the slack channel
      post("----------------------------")
      post(":rocket: WDPA release #{label} started (#{Rails.env})")
    end

    # Generic phase text notifier; keep for backwards compatibility
    # If counts is a nested structure, we summarise it to avoid overly long Slack messages.
    def phase(text, counts: nil, tables: nil)
      extra = []
      extra << summarise(counts) if counts
      extra << tables&.join(', ') if tables
      post(":information_source: #{text} #{extra.compact.join(' | ')}")
    end

    # Explicit phase-complete notifier (can be silenced via env)
    def phase_complete(phase, duration_s: nil)
      return unless phase_notifications_enabled?

      suffix = duration_s ? " in #{format('%.1f', duration_s)}s" : ''
      title, expl = friendly_phase_and_explainer(phase)
      expl_text = expl ? " — #{expl}" : ''
      post(":white_check_mark: #{title} complete#{suffix}#{expl_text}")
    end

    def success
      post(":tada: Release #{@label} succeeded")
    end

    def error(e, phase:)
      post(":rotating_light: Release #{@label} failed in #{phase}: #{e.message}")
    end

    def progress(processed_count, total_estimated = nil, _phase = 'import')
      return unless Wdpa::Portal::Config::PortalImportConfig.progress_notifications_enabled?

      message = "It is now importing #{format_number(processed_count)} out of #{format_number(total_estimated)} protected areas"
      post(":hourglass_flowing_sand: #{message}")
    end

    def import_completion(processed_count, _phase = 'import')
      message = "Import completed: #{format_number(processed_count)} protected areas processed"
      post(":white_check_mark: #{message}")
    end

    # Rollback notifications
    def rollback_ok(timestamp)
      post(":rewind: Rollback to backup #{timestamp} succeeded")
    end

    def rollback_failed(e, timestamp)
      post(":rotating_light: Rollback to backup #{timestamp} failed: #{e.message}")
    end

    private

    def post(msg)
      post_json(text: msg)
    end

    def post_json(hash)
      Rails.logger.info("[Notifier] #{hash[:text] || '[blocks]'}")
      return unless @webhook

      uri = URI.parse(@webhook)
      Net::HTTP.post(uri, hash.to_json, 'Content-Type' => 'application/json')
    rescue StandardError => e
      Rails.logger.warn("Slack notify failed: #{e.message}")
    end

    def phase_notifications_enabled?
      v = ENV['PP_RELEASE_SLACK_PHASE_COMPLETE']
      # default to true unless explicitly set to a false-ish value
      !(v && %w[0 false no off].include?(v.to_s.downcase))
    end

    def verbose?
      ActiveModel::Type::Boolean.new.cast(ENV['PP_RELEASE_SLACK_VERBOSE'])
    end

    def format_number(number)
      number.to_s.reverse.gsub(/(\d{3})(?=.)/, '\1,').reverse
    end

    # Turn a nested Hash/Array structure (like importer results) into a concise summary string.
    # - Hashes are flattened using dot notation (e.g., sources.imported_count=514)
    # - Arrays are replaced by their counts; in verbose mode we add a small preview
    # - Output is limited to a configurable number of parts to keep Slack messages short
    def summarise(obj)
      parts = flatten_kv(obj)
      max_parts = (ENV['PP_RELEASE_SLACK_MAX_PARTS'] || 40).to_i
      text = parts.first(max_parts).join(', ')
      text += ", … +#{parts.length - max_parts} more" if parts.length > max_parts
      text
    end

    def flatten_kv(obj, prefix = nil)
      case obj
      when Hash
        obj.flat_map do |k, v|
          key = prefix ? "#{prefix}.#{k}" : k.to_s
          case v
          when Hash
            flatten_kv(v, key)
          when Array
            [summarise_array(key, v)]
          else
            ["#{key}=#{v}"]
          end
        end
      when Array
        [summarise_array(prefix || 'items', obj)]
      else
        ["#{prefix || 'value'}=#{obj}"]
      end
    end

    def summarise_array(key, arr)
      return "#{key}=0" if arr.nil? || arr.empty?

      if verbose?
        preview_count = (ENV['PP_RELEASE_SLACK_PREVIEW_COUNT'] || 5).to_i
        preview = arr.first(preview_count).map { |e| e.to_s }.join(', ')
        suffix = arr.length > preview_count ? ', …' : ''
        "#{key}=#{arr.length} [#{preview}#{suffix}]"
      else
        "#{key}=#{arr.length}"
      end
    end

    # Format a human-readable Block Kit card for the core importer results.
    # Focuses on the most meaningful metrics, no dot-notation.
    public

    def import_core_summary(results)
      ok = !!value(results, :success)
      hard_errors = Array(value(results, :hard_errors)).size
      status_text = ok ? 'Succeeded' : 'Failed'

      src_count = value(results, :sources, :imported_count)
      pa_attrs = value(results, :protected_areas, :protected_areas_attributes, :imported_count)
      pa_geom_areas   = value(results, :protected_areas, :protected_areas_geometries, :protected_areas, :imported_count)
      pa_geom_parcels = value(results, :protected_areas, :protected_areas_geometries, :protected_area_parcels,
        :imported_count)
      fields_updated = value(results, :global_stats, :fields_updated)

      gl_imported   = value(results, :green_list, :imported_count)
      gl_not_found  = Array(value(results, :green_list, :not_found_site_ids)).size
      gl_invalid    = Array(value(results, :green_list, :invalid_site_ids)).size
      gl_duplicates = Array(value(results, :green_list, :duplicates)).size

      pame_imported = value(results, :pame, :imported_count)
      pame_unrec    = Array(value(results, :pame, :site_ids_not_recognised)).size

      blocks = [
        { type: 'header', text: { type: 'plain_text', text: "Import core — #{status_text}", emoji: true } },
        { type: 'context', elements: [{ type: 'mrkdwn', text: "Label: `#{@label}` · Hard errors: #{hard_errors}" }] },
        { type: 'section', text: { type: 'mrkdwn', text: '*Summary*' } },
        {
          type: 'section',
          fields: [
            { type: 'mrkdwn', text: "*Sources imported*\n#{src_count || 0}" },
            { type: 'mrkdwn', text: "*Protected areas imported*\n#{pa_attrs || 0}" },
            { type: 'mrkdwn', text: "*Geometries (areas/parcels)*\n#{pa_geom_areas || 0} / #{pa_geom_parcels || 0}" },
            { type: 'mrkdwn', text: "*Global statistics fields updated*\n#{fields_updated || 0}" },
            { type: 'mrkdwn',
              text: "*Green List*\n#{gl_imported || 0} (Not found #{gl_not_found}, Invalid #{gl_invalid}#{gl_duplicates.positive? ? ", Duplicates #{gl_duplicates}" : ''})" },
            { type: 'mrkdwn',
              text: "*PAME*\n#{pame_imported || 0}#{pame_unrec.positive? ? " (Unrecognised #{pame_unrec})" : ''}" }
          ]
        }
      ]

      post_json(text: 'Import core completed', blocks: blocks)
    end

    private

    # Provide a friendly title and a short explainer for each phase
    def friendly_phase_and_explainer(phase)
      key = phase.to_s
      case key
      when 'acquire_lock'
        ['acquire_lock', 'Ensure single release run (advisory lock)']
      when 'refresh_views'
        ['refresh_views', 'Refresh portal materialized views']
      when 'preflight'
        ['preflight', 'Checks: views exist, counts, geometry, duplicates']
      when 'create_portal_downloads_view'
        ['create_portal_downloads_view', 'Delete and recreate combined file generator downloads view']
      when 'build_staging'
        ['build_staging', 'Create/prepare staging tables']
      when 'import_core'
        ['import_core', 'Import sources, protected areas, stats, green list, PAME']
      when 'import_related'
        ['import_related', 'Import related datasets (e.g., country stats, story maps)']
      when 'validate_and_manifest'
        ['validate_and_manifest', 'Sanity checks and write manifest']
      when 'finalise_swap'
        ['finalise_swap', 'Promote staging to live tables']
      when 'post_swap'
        ['post_swap', 'Analyze tables and clear caches']
      when 'cleanup'
        ['cleanup', 'Retention and cleanup tasks']
      when 'cleanup_and_retention'
        ['cleanup', 'Retention and cleanup tasks']
      when 'release_lock'
        ['release_lock', 'Release advisory lock']
      else
        [key, nil]
      end
    end

    # Safe dig that accepts symbol or string keys at each level
    def value(h, *keys)
      keys.reduce(h) do |acc, key|
        acc[key] || acc[key.to_s] if acc.is_a?(Hash)
      end
    end
  end
end
