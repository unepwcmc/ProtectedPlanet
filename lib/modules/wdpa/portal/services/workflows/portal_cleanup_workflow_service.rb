# frozen_string_literal: true

module Wdpa
  module Portal
    module Services
      module Workflows
        class PortalCleanupWorkflowService

          # Run postgres vaccum etc... + cleanup_old_backups
          def self.cleanup_after_swap
            Rails.logger.info '🧹 Cleaning up after swap...'

            begin
              Wdpa::Portal::Services::Core::TableCleanupService.cleanup_after_swap
              Rails.logger.info '✅ Cleanup completed'
            rescue StandardError => e
              Rails.logger.error "❌ Failed to cleanup after workflow: #{e.message}"
              raise e
            end
          end

          # Only cleanup old backup tables
          def self.cleanup_old_backups(keep_count)
            Rails.logger.info "🧹 Cleaning up backup tables, keeping the last #{keep_count} backups..."

            begin
              cleaned_count = Wdpa::Portal::Services::Core::TableCleanupService.cleanup_old_backups(keep_count)
              Rails.logger.info "✅ Cleaned up #{cleaned_count} old backup tables"
              cleaned_count
            rescue StandardError => e
              Rails.logger.error "❌ Cleanup failed: #{e.message}"
              raise e
            end
          end
        end
      end
    end
  end
end
