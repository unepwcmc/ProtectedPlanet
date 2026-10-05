# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      class Greenlist
        include KeysetBatches

        KEY_COLUMNS = %w[id].freeze

        private

        def greenlist_view
          Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views[:greenlist]
        end

        public

        def find_in_batches(&block)
          unless greenlist_view_exists?
            raise StandardError,
              "#{greenlist_view} view is required but does not exist"
          end

          batch_size = Wdpa::Portal::Config::PortalImportConfig.batch_import_greenlist_from_view_size
          each_keyset_batch(view: greenlist_view, key_columns: KEY_COLUMNS, batch_size: batch_size, &block)
        end

        def each(&block)
          find_in_batches do |batch|
            batch.each(&block)
          end
        end

        def count
          unless greenlist_view_exists?
            raise StandardError,
              "#{greenlist_view} view is required but does not exist"
          end
          ActiveRecord::Base.lease_connection.select_value("SELECT COUNT(*) FROM #{greenlist_view}").to_i
        end

        def greenlist_view_exists?
          Wdpa::Portal::Managers::ViewManager.materialized_view_exists?(greenlist_view)
        end
      end
    end
  end
end
