# frozen_string_literal: true

module Wdpa
  module Portal
    module Services
      module Workflows
        class PortalImportWorkflowService
          def self.run_complete_workflow
            new.run_complete_workflow
          end

          def run_complete_workflow
            Rails.logger.info '🚀 Starting Complete Portal Import Workflow'

            begin
              # Step 1: Create staging tables
              unless create_staging_tables
                Rails.logger.error '❌ Failed to create staging tables. Stopping workflow.'
                return false
              end

              # Step 2: Import data to staging
              unless import_data_to_staging
                Rails.logger.error '❌ Failed to import data to staging. Stopping workflow.'
                return false
              end

              # Step 3: Promote staging to live
              unless promote_staging_to_live
                Rails.logger.error '❌ Failed to promote staging to live. Stopping workflow.'
                return false
              end

              # Step 4: Cleanup after workflow
              unless cleanup_after_workflow
                Rails.logger.error '❌ Failed to cleanup after workflow. Stopping workflow.'
                return false
              end

              Rails.logger.info '🎉 Portal Import Workflow completed successfully!'
              true
            rescue StandardError => e
              Rails.logger.error "❌ Portal import workflow failed: #{e.message}"
              Rails.logger.error e.backtrace.first(5).join("\n") if Rails.env.development?
              false
            end
          end

          private

          def create_staging_tables
            Rails.logger.info '🏗️ Creating staging tables...'
            Wdpa::Portal::Managers::StagingTableManager.create_staging_tables
            Rails.logger.info '✅ Staging tables created'
            true
          rescue StandardError => e
            Rails.logger.error "❌ Failed to create staging tables: #{e.message}"
            false
          end

          def import_data_to_staging
            Rails.logger.info '📥 Importing data to staging tables...'
            refresh_materialized_views
            @results = Wdpa::Portal::Importer.import(refresh_materialized_views: false)

            unless check_for_import_errors
              Rails.logger.error '❌ Import completed with errors. Stopping workflow.'
              return false
            end

            Rails.logger.info '✅ Data imported to staging tables'
            true
          rescue StandardError => e
            Rails.logger.error "❌ Failed to import data to staging: #{e.message}"
            false
          end

          def promote_staging_to_live
            Rails.logger.info '🔄 Promoting staging tables to live...'
            Wdpa::Portal::Services::Core::TableSwapService.promote_staging_to_live
            Rails.logger.info '✅ Staging tables promoted to live'
            true
          rescue StandardError => e
            Rails.logger.error "❌ Failed to promote staging to live: #{e.message}"
            false
          end

          def cleanup_after_workflow
            Rails.logger.info '🧹 Cleaning up after swap...'
            Wdpa::Portal::Services::Core::TableCleanupService.cleanup_after_swap
            Rails.logger.info '✅ Cleanup completed'
            true
          rescue StandardError => e
            Rails.logger.error "❌ Failed to cleanup after workflow: #{e.message}"
            false
          end

          def check_for_import_errors
            return true unless @results.is_a?(Hash) && @results[:hard_errors] && @results[:hard_errors].any?

            Rails.logger.error "❌ Import completed with hard errors: #{@results[:hard_errors].join(', ')}"
            false
          end

          def refresh_materialized_views
            Rails.logger.info 'Refreshing materialized views...'
            Wdpa::Portal::Managers::ViewManager.refresh_materialized_views
            Rails.logger.info '✅ Materialized views refreshed successfully'
          rescue StandardError => e
            Rails.logger.error "❌ Failed to refresh materialized views: #{e.message}"
            raise e
          end
        end
      end
    end
  end
end
