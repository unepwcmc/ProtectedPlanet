# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      class Pames
        include KeysetBatches

        private

        def pame_view
          Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views[:pame]
        end

        public

        def find_in_batches(&block)
          unless portal_views_exist?
            raise StandardError, "#{pame_view} view is required but does not exist"
          end

          batch_size = Wdpa::Portal::Config::PortalImportConfig.batch_import_pame_from_view_size
          key_columns = Wdpa::Portal::Utils::PameColumnMapper::KEY_COLUMNS
          each_keyset_batch(view: pame_view, key_columns: key_columns, batch_size: batch_size, &block)
        end

        def count
          if portal_views_exist?
            ActiveRecord::Base.lease_connection.select_value("SELECT COUNT(*) FROM #{pame_view}").to_i
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
