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
            puts '📋 Available backups:'
            puts '===================='

            begin
              backups = Wdpa::Portal::Services::Core::TableRollbackService.list_available_backups
              log_backup_listing_results(backups)
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

          def log_backup_listing_results(backups)
            if backups.empty?
              puts 'No backups found'
            else
              backups.each do |timestamp, tables|
                puts "📅 #{timestamp}:"
                tables.each do |table_info|
                  puts "  - #{table_info[:table]} (#{table_info[:backup_table]})"
                end
                puts ''
              end
            end
          end
        end
      end
    end
  end
end
