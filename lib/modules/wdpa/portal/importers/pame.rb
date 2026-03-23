# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      class Pame < Base
        def self.import_to_staging(notifier: nil)
          Rails.logger.info 'Deleting old staging PAME evaluations...'
          Staging::PameEvaluation.delete_all
          Rails.logger.info 'Importing staging PAME evaluations...'
          soft_errors = []
          adapter = Wdpa::Portal::Adapters::ImportViewsAdapter.new
          relation = adapter.pames_relation
          total_count = relation.count
          imported_count = 0

          relation.find_in_batches do |batch|
            batch.each do |row|
              ActiveRecord::Base.transaction do
                result = Wdpa::Portal::Utils::PameColumnMapper.map_portal_pame_to_pp_evaluation(row)
                pa = result[:pa]
                attrs = result[:attributes_for_create]

                if pa.nil?
                  soft_errors << "Row skipped (missing protected area/parcel) for asmt_id #{attrs['asmt_id']}, site_id #{attrs['site_id']}, site_pid #{attrs['site_pid']}"
                  next
                end

                pame_evaluation = Staging::PameEvaluation.create!(attrs)
                countries = pa.countries
                pame_evaluation.countries << countries if countries.any?
                imported_count += 1
              end
            rescue StandardError => e
              error_message = "Row error processing evaluation_id #{row['asmt_id']}: #{e.message}"
              soft_errors << error_message
              Rails.logger.error error_message
            end
          end

          skipped_count = total_count - imported_count
          message = "#{imported_count} PAME evaluations imported. #{skipped_count} skipped. #{soft_errors.count} soft errors."
          Rails.logger.info message
          notifier&.phase(message)

          build_result(imported_count, soft_errors, [], { skipped_count: skipped_count })
        rescue StandardError => e
          notifier&.phase("Import PAME evaluations failed. #{e.message}")
          failure_result("Import failed: #{e.message}", 0, { skipped_count: 0 })
        end
      end
    end
  end
end
