# frozen_string_literal: true
module Wdpa
  module Portal
    module Importers
      class GreenList < Base
        def self.import_to_staging(notifier: nil)
          Rails.logger.info 'Clearing existing staging green list data...'
          clear_existing_data
          Rails.logger.info 'Importing staging green list from portal view...'

          soft_errors = []
          adapter = Wdpa::Portal::Adapters::ImportViewsAdapter.new
          relation = adapter.greenlist_relation
          total_count = relation.count
          imported_count = 0

          relation.find_in_batches do |batch|
            batch.each do |row|
              # Single entry point: map + resolve PA/parcel (same pattern as PameColumnMapper.map_portal_pame_to_pp_evaluation)
              green_list_result = Wdpa::Portal::Utils::GreenListColumnMapper.map_portal_greenlist_to_pp_greenlist(row)
              pa = green_list_result[:pa]
              gl_attrs = green_list_result[:attributes_for_create] || {}

              if pa.blank?
                soft_errors << "No parcel or protected_area found for site_id #{row['site_id']} site_pid #{row['site_pid']}"
              else
                ActiveRecord::Base.transaction do
                  gls = Staging::GreenListStatus.create!(gl_attrs)
                  # Update the protected_area or protected_area_parcel with the green_list_status_id
                  # Do not use pa.update!(green_list_status_id: gls.id) as it will trigger validations and callbacks to slow down
                  pa.update_columns(green_list_status_id: gls.id, updated_at: Time.current)
                  imported_count += 1
                end
              end
            rescue StandardError => e
              site_id = row['site_id']
              error_message = "Row error processing site_id #{site_id}, site_pid #{row['site_pid']}: #{e.message}"
              soft_errors << error_message
              Rails.logger.error error_message
            end
          end

          skipped_count = total_count - imported_count
          message = "#{imported_count} Green list records imported. #{skipped_count} skipped. #{soft_errors.count} soft errors."
          Rails.logger.info message
          notifier&.phase(message)

          build_result(imported_count, soft_errors, [], { skipped_count: skipped_count })
        rescue StandardError => e
          Rails.logger.error "Green list import failed: #{e.message}"
          notifier&.phase("Import failed at Green List importer: #{e.message}")
          failure_result("Import failed at Green List importer: #{e.message}", 0, { skipped_count: 0 })
        end

        def self.clear_existing_data
          Staging::ProtectedArea.where.not(green_list_status_id: nil)
            .update_all(green_list_status_id: nil)
          Staging::ProtectedAreaParcel.where.not(green_list_status_id: nil)
            .update_all(green_list_status_id: nil)
          Staging::GreenListStatus.destroy_all

          Rails.logger.info 'Cleared existing staging green list data'
        end
      end
    end
  end
end
