# frozen_string_literal: true

# Simple checkpoint store for Step 2 importers.
# Uses the current Release (by release_id) if available to persist checkpoints in stats_json.
# Falls back to a tmp JSON file if no release_id is provided.
module Wdpa
  module Portal
    module Checkpoint
      FILE_PATH = Rails.root.join('tmp', 'portal_checkpoints.json')

      class << self
        # Memoized per release, NOT per process.
        #
        # This was a bare `@store ||=`, memoized for the life of the process. Only
        # reset_all! cleared it, and that runs solely as the last phase of a
        # *successful* PortalRelease::Service run. Anything else — a direct
        # Wdpa::Portal::Importer.import, a failed or partial release, a second
        # import in the same Ruby process — left the previous release's cursors in
        # memory, so the next release resumed from them.
        #
        # Latent in production, which runs one release per process
        # (rake pp:portal:release), so the release id never changes mid-process.
        # It bites a console running two imports, a dry run and resume in one
        # session, and the test suite — and would bite production if imports ever
        # moved into a long-lived worker.
        #
        # Measured 2026-09-16, two imports in one process against one seeded row:
        #   Jan2026 (release 49): imported=1, @store cursor => [1]
        #   Feb2026 (release 50): imported=0, success=false — still reading
        #                         release 49's cursor; release 50's own stats_json
        #                         checkpoints were never loaded (nil)
        # That is the "Target staging table staging_protected_areas does not exist
        # or has no records" failure, and the cause of the order-dependent failure
        # in release_orchestration_integration_test.rb (seed 3923).
        #
        # Reloading whenever the current release changes makes each release read
        # its own checkpoints, while resume WITHIN a release still works.
        def store
          release_id = Wdpa::Portal::ImportRuntimeConfig.release_id
          if @store.nil? || @store_release_id != release_id
            @store = nil
            @store_release_id = release_id
          end

          @store ||= begin
            release = current_release
            if release
              stats = release.stats_json || {}
              stats['checkpoints'] ||= {}
              stats['checkpoints']
            else
              # The file store is global — one file shared by every run — so
              # offsets found in it cannot be shown to belong to THIS run.
              # reset_all! only runs as the last phase of a successful release
              # (PortalRelease::Service::PHASES), so a crash, an abort, a dry
              # run, or a partial PP_RELEASE_ONLY_PHASES subset all leave
              # offsets behind.
              #
              # Reaching this branch during a release is itself a bug: a real
              # release passes release_id (service.rb:187) and takes the
              # Release-scoped branch above.
              Rails.logger.warn(
                "⚠️ Portal checkpoints falling back to the shared file store #{FILE_PATH} " \
                "(release_id=#{Wdpa::Portal::ImportRuntimeConfig.release_id.inspect}). " \
                'Reaching this branch during a release is a bug.'
              )
              ensure_file_store
              discard_unowned_file_store!
            end
          rescue StandardError => e
            # Was a bare `rescue; {}`, which hid a NameError for years: importers
            # then saw an empty store and quietly re-imported (or skipped) everything.
            Rails.logger.warn("⚠️ Failed to load portal checkpoints, continuing with an empty store: #{e.class}: #{e.message}")
            {}
          end
        end

        def persist!
          release = current_release
          if release
            all_stats = release.stats_json || {}
            all_stats['checkpoints'] = store
            release.update_columns(stats_json: all_stats, updated_at: Time.current)
          else
            ensure_file_store
            File.write(FILE_PATH, JSON.pretty_generate(store))
          end
          true
        end

        # Reset all checkpoints (attributes, geometry, etc.) after a run
        def reset_all!
          Rails.logger.info '🧹 Resetting portal checkpoints after run'
          @store = {}
          @store_release_id = Wdpa::Portal::ImportRuntimeConfig.release_id
          persist!
        rescue StandardError => e
          Rails.logger.warn "⚠️ Failed to reset checkpoints: #{e.message}"
        end

        # Keyset cursors for view batches, one per view: the key columns of the
        # last row handed to the importer. An offset cannot resume an unordered
        # LIMIT/OFFSET scan — see Adapters::KeysetBatches.
        def get_cursor(view_name)
          store.dig('attributes', view_name.to_s, 'cursor')
        end

        def set_cursor(view_name, cursor)
          store['attributes'] ||= {}
          store['attributes'][view_name.to_s] ||= {}
          store['attributes'][view_name.to_s]['cursor'] = cursor
          persist!
        end

        # Geometry processed per view toggles
        def geometry_done?(view_name, table_name = nil)
          if table_name
            !!store.dig('geometry', view_name.to_s, table_name.to_s, 'done')
          else
            # Backward compatibility: check if any table has this view done
            geometry_section = store.dig('geometry', view_name.to_s)
            return false unless geometry_section
            geometry_section.values.any? { |table_data| table_data['done'] }
          end
        end

        def mark_geometry_done(view_name, table_name = nil)
          store['geometry'] ||= {}
          store['geometry'][view_name.to_s] ||= {}
          if table_name
            store['geometry'][view_name.to_s][table_name.to_s] ||= {}
            store['geometry'][view_name.to_s][table_name.to_s]['done'] = true
          else
            # Backward compatibility: mark for all tables
            store['geometry'][view_name.to_s]['done'] = true
          end
          persist!
        end

        private

        # Start the shared file store empty rather than resuming from a cursor of
        # unknown provenance.
        #
        # The trade: a run using the file store can no longer resume across
        # processes. That capability was not safe to have — the two outcomes are
        # re-importing rows that are already there (idempotent; staging tables are
        # rebuilt per release) versus skipping rows that were never imported, which
        # surfaces as "Target staging table staging_protected_areas does not exist
        # or has no records" and is not recoverable without noticing it happened.
        #
        # Release-scoped checkpoints are untouched: those offsets provably belong
        # to their release, so resume within a release still works.
        def discard_unowned_file_store!
          contents = JSON.parse(File.read(FILE_PATH))
          return contents if contents.empty?

          Rails.logger.warn(
            "⚠️ Discarding stale portal checkpoints #{contents.keys.inspect} from #{FILE_PATH}: " \
            'the shared file store cannot be shown to belong to this run, and trusting it ' \
            'would silently skip records. Starting from an empty store.'
          )
          File.write(FILE_PATH, '{}')
          {}
        end

        def current_release
          release_id = Wdpa::Portal::ImportRuntimeConfig.release_id
          return nil if release_id.nil?

          ::Release.find_by(id: release_id)
        rescue StandardError => e
          Rails.logger.warn("⚠️ Could not load Release #{release_id.inspect} for portal checkpoints: #{e.class}: #{e.message}")
          nil
        end

        def ensure_file_store
          FileUtils.mkdir_p(File.dirname(FILE_PATH))
          File.write(FILE_PATH, '{}') unless File.exist?(FILE_PATH)
        end
      end
    end
  end
end

