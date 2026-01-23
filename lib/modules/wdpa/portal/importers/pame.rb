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
                pame_attributes = Wdpa::Portal::Utils::PameColumnMapper.map_portal_pame_to_attributes(row)
                asmt_id               = pame_attributes['asmt_id']
                site_id               = pame_attributes['site_id']
                site_pid              = pame_attributes['site_pid'].presence || site_id&.to_s || nil
                method                = pame_attributes['method']
                pame_method           = method.present? ? PameMethod.find_or_create_by!(name: method) : nil
                # We try to find parcel first, if not found that means it is not multiple parcels
                protected_area_parcel = Staging::ProtectedAreaParcel.find_by(site_id: site_id, site_pid: site_pid) || nil
                protected_area        = (protected_area_parcel ? nil : Staging::ProtectedArea.find_by_site_id(site_id)) || nil
                pa_name               = protected_area_parcel&.name.to_s || protected_area&.name.to_s || nil
                eff_metaid            = pame_attributes['eff_metaid']

                pame_evaluation = Staging::PameEvaluation.create!(
                  asmt_id: asmt_id,
                  protected_area: protected_area,
                  protected_area_parcel: protected_area_parcel,
                  # TODO: If finding no need of site_id and site_pid, we can remove them in table migration
                  site_id: site_id,
                  site_pid: site_pid,
                  pame_method: pame_method,
                  # TODO: If finding no need of method as we have pame_method link up, we can remove it in table migration
                  method: pame_attributes['method'],
                  asmt_year: pame_attributes['asmt_year'],
                  name: pa_name,
                  pame_source: Staging::PameSource.find_by(id: eff_metaid),
                  # TODO: If finding no need of eff_metaid, we can remove it in table migration
                  eff_metaid: eff_metaid,
                  asmt_url: pame_attributes['asmt_url'],
                  info_url: pame_attributes['info_url'],
                  verif_eff: pame_attributes['verif_eff'],
                  gov_act: pame_attributes['gov_act'],
                  gov_asmt: pame_attributes['gov_asmt'],
                  dp_bio: pame_attributes['dp_bio'],
                  dp_other: pame_attributes['dp_other'],
                  mgmt_obset: pame_attributes['mgmt_obset'],
                  mgmt_obman: pame_attributes['mgmt_obman'],
                  mgmt_adapt: pame_attributes['mgmt_adapt'],
                  mgmt_staff: pame_attributes['mgmt_staff'],
                  mgmt_budgt: pame_attributes['mgmt_budgt'],
                  mgmt_thrts: pame_attributes['mgmt_thrts'],
                  mgmt_mon: pame_attributes['mgmt_mon'],
                  out_bio: pame_attributes['out_bio']
                )

                if protected_area_parcel.present?
                  protected_area_parcel.countries.each do |country|
                    pame_evaluation.countries << country unless pame_evaluation.countries.include?(country)
                  end
                elsif protected_area.present?
                  protected_area.countries.each do |country|
                    pame_evaluation.countries << country unless pame_evaluation.countries.include?(country)
                  end
                end
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
