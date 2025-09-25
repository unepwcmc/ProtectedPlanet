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
              ensure_file_store
              JSON.parse(File.read(FILE_PATH))
            end
          rescue StandardError
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

        # Offsets for attributes batches per view
        def get_offset(view_name)
          store.dig('attributes', view_name.to_s, 'offset').to_i
        end

        def set_offset(view_name, offset)
          store['attributes'] ||= {}
          store['attributes'][view_name.to_s] ||= {}
          store['attributes'][view_name.to_s]['offset'] = offset.to_i
          persist!
        end

        # Geometry processed per view toggles
        def geometry_done?(view_name)
          !!store.dig('geometry', view_name.to_s, 'done')
        end

        def mark_geometry_done(view_name)
          store['geometry'] ||= {}
          store['geometry'][view_name.to_s] ||= {}
          store['geometry'][view_name.to_s]['done'] = true
          persist!
        end

        private

        def current_release
          release_id = Wdpa::Portal::ImportRuntimeConfig.release_id
          return nil if release_id.nil?
          Release.find_by(id: release_id)
        rescue StandardError
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

