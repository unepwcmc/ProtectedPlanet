# frozen_string_literal: true

module Wdpa
  module Portal
    module Services
      module Workflows
        class PortalRollbackWorkflowService
          def self.rollback_to_backup(timestamp)
            new.rollback_to_backup(timestamp)
          end

          def self.list_available_backups
            new.list_available_backups
          end

          def rollback_to_backup(timestamp)
            validate_timestamp(timestamp)
            Rails.logger.info "🔄 Rolling back to backup: #{timestamp}"

            begin
              Wdpa::Portal::Services::Core::TableRollbackService.rollback_to_backup(timestamp)
              Rails.logger.info '✅ Rollback completed successfully'
            rescue StandardError => e
              Rails.logger.error "❌ Rollback failed: #{e.message}"
              raise e
            end
          end

          def list_available_backups
            puts '📋 Available backups: (YYMMDDHHMM)'
            puts '===================='

            begin
              backups = Wdpa::Portal::Services::Core::TableRollbackService.list_available_backups
              puts 'No backups found' if backups.empty?
              backups
            rescue StandardError => e
              puts "❌ Failed to list backups: #{e.message}"
              raise e
            end
          end

          private

          def validate_timestamp(timestamp)
            return unless timestamp.nil? || timestamp.empty?

            puts '❌ Please provide a backup timestamp'
            puts 'Usage: rake portal_importer:rollback[20250110_143022]'
            puts 'Run "rake portal_importer:list_backups" to see available timestamps'
            exit 1
          end
        end
      end
    end
  end
end
