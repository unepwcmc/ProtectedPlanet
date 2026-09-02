# frozen_string_literal: true

# Simple checkpoint store for Step 2 importers.
# Uses the current Release (by release_id) if available to persist checkpoints in stats_json.
# Falls back to a tmp JSON file if no release_id is provided.
module Wdpa
  module Portal
    module Checkpoint
      FILE_PATH = Rails.root.join('tmp', 'portal_checkpoints.json')

      class << self
        def store
          @store ||= begin
            release = current_release
            if release
              stats = release.stats_json || {}
              stats['checkpoints'] ||= {}
              stats['checkpoints']
            else
              # The file store is global — it is shared by every release, so a
              # run that ends without reset_all! (a dry run, a crash) leaves
              # offsets behind that make the NEXT release import 0 records. Say
              # so loudly; reaching this branch during a release is a bug.
              Rails.logger.warn(
                "⚠️ Portal checkpoints falling back to the shared file store #{FILE_PATH} " \
                "(release_id=#{Wdpa::Portal::ImportRuntimeConfig.release_id.inspect}). " \
                'Stale offsets here can silently skip the whole import.'
              )
              ensure_file_store
              JSON.parse(File.read(FILE_PATH))
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

