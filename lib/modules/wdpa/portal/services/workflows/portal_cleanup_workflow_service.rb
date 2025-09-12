# frozen_string_literal: true

module Wdpa
  module Portal
    module Services
      module Workflows
        class PortalCleanupWorkflowService
          def self.cleanup_old_backups(keep_count = 3)
            new.cleanup_old_backups(keep_count)
          end

          def cleanup_old_backups(keep_count)
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
