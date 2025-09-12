# frozen_string_literal: true

module Wdpa
  module Portal
    module Services
      module Workflows
        class PortalStructureComparisonWorkflowService
          def self.compare_structures
            new.compare_structures
          end

          def compare_structures
            log_comparison_start

            begin
              success = Wdpa::Portal::Services::Core::TableStructureComparisonService.compare_live_vs_staging_tables
              log_comparison_results(success)
              success
            rescue StandardError => e
              log_comparison_failure(e)
              raise e
            end
          end

          private

          def log_comparison_start
            Rails.logger.info '🔍 Comparing Live vs Staging Table Structures'
          end

          def log_comparison_results(success)
            if success
              Rails.logger.info '🎉 All staging tables match their live counterparts perfectly!'
            else
              Rails.logger.warn '⚠️ Some tables have structural differences'
            end
          end

          def log_comparison_failure(error)
            Rails.logger.error "❌ Failed to compare table structures: #{error.message}"
            Rails.logger.error error.backtrace.first(5).join("\n") if Rails.env.development?
          end
        end
      end
    end
  end
end
