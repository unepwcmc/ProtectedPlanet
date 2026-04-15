# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      class Greenlist
        private

        def greenlist_view
          Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views[:greenlist]
        end

        public

        def find_in_batches
          batch_size = Wdpa::Portal::Config::PortalImportConfig.batch_import_greenlist_from_view_size
          sample_limit = Wdpa::Portal::ImportRuntimeConfig.sample_limit
          use_checkpoints = Wdpa::Portal::ImportRuntimeConfig.checkpoints?

          unless greenlist_view_exists?
            raise StandardError,
              "#{greenlist_view} view is required but does not exist"
          end

          total_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{greenlist_view}").to_i
          offset = 0
          if use_checkpoints
            begin
              offset = Wdpa::Portal::Checkpoint.get_offset(greenlist_view)
            rescue StandardError
              offset = 0
            end
          end

          end_offset = sample_limit ? [offset + sample_limit, total_count].min : total_count

          while offset < end_offset
            limit = [batch_size, end_offset - offset].min
            query = "SELECT * FROM #{greenlist_view} LIMIT #{limit} OFFSET #{offset}"
            result = ActiveRecord::Base.connection.select_all(query)
            # Yield array of hashes so each row is a plain Hash (string keys)
            batch = result.respond_to?(:to_a) ? result.to_a : result
            yield batch
            offset += limit
            Wdpa::Portal::Checkpoint.set_offset(greenlist_view, offset) if use_checkpoints
          end
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
          ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{greenlist_view}").to_i
        end

        def greenlist_view_exists?
          Wdpa::Portal::Managers::ViewManager.materialized_view_exists?(greenlist_view)
        end
      end
    end
  end
end
