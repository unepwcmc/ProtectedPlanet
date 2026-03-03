# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      class Pames
        private
        def pame_view
          Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views[:pame]
        end

        public
        def find_in_batches
          batch_size = Wdpa::Portal::Config::PortalImportConfig.batch_import_pame_from_view_size
          sample_limit = Wdpa::Portal::ImportRuntimeConfig.sample_limit
          use_checkpoints = Wdpa::Portal::ImportRuntimeConfig.checkpoints?

          if portal_views_exist?
            total_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{pame_view}").to_i
            offset = 0
            if use_checkpoints
              begin
                offset = Wdpa::Portal::Checkpoint.get_offset(pame_view)
              rescue StandardError
                offset = 0
              end
            end

            end_offset = sample_limit ? [offset + sample_limit, total_count].min : total_count

            while offset < end_offset
              limit = [batch_size, end_offset - offset].min
              query = "SELECT * FROM #{pame_view} LIMIT #{limit} OFFSET #{offset}"
              batch = ActiveRecord::Base.connection.select_all(query)
              yield batch
              offset += limit
              Wdpa::Portal::Checkpoint.set_offset(pame_view, offset) if use_checkpoints
            end
          else
            missing_views = [pame_view, sources_view].reject do |view|
              Wdpa::Portal::Managers::ViewManager.materialized_view_exists?(view)
            end
            raise StandardError,
              "#{missing_views.join(', ')} view(s) required but do not exist"
          end
        end

        def count
          if portal_views_exist?
            ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{pame_view}").to_i
          else
            raise StandardError,
              "#{pame_view} view is required but does not exist"
          end
        end

        def portal_views_exist?
          Wdpa::Portal::Managers::ViewManager.materialized_view_exists?(pame_view)
        end
      end
    end
  end
end
