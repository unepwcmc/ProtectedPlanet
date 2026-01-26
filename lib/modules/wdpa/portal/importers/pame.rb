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
          imported_count = 0

          relation.find_in_batches do |batch|
            batch.each do |row|
              ActiveRecord::Base.transaction do
                pame_attributes = Wdpa::Portal::Utils::PameColumnMapper.map_portal_pame_to_pp_evaluation(row)

                if pame_attributes['protected_area'].nil? && pame_attributes['protected_area_parcel'].nil?
                  asmt_id = pame_attributes['asmt_id']
                  site_id = pame_attributes['site_id']
                  site_pid = pame_attributes['site_pid']
                  soft_errors << "Row skipped (missing protected area/parcel) for asmt_id #{asmt_id}, site_id #{site_id}, site_pid #{site_pid}"
                  next
                end

                pame_evaluation = Staging::PameEvaluation.create!(pame_attributes)

                countries = if pame_evaluation.protected_area_parcel.present?
                              pame_evaluation.protected_area_parcel.countries
                            elsif pame_evaluation.protected_area.present?
                              pame_evaluation.protected_area.countries
                            else
                              []
                            end

                pame_evaluation.countries << countries if countries.any?
                imported_count += 1
              end
            rescue StandardError => e
            soft_errors << "Row error processing evaluation_id #{row['asmt_id']}: #{e.message}"
              Rails.logger.error "Error processing PAME row: #{e.message}"
            end
          end

          Rails.logger.info 'Staging PAME import completed successfully'
          Rails.logger.info "Total PAME evaluations imported: #{imported_count}"
          notifier&.phase("#{imported_count} PAME evaluations imported.")

          build_result(imported_count, soft_errors, [])
        rescue StandardError => e
          notifier&.phase("Import PAME evaluations failed. #{e.message}")
          failure_result("Import failed: #{e.message}", 0)
        end
      end
    end
  end
end
