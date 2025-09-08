# frozen_string_literal: true

require 'csv'

module Wdpa
  module Shared
    module Importer
      class CountryOverseasTerritories
        # NOTE: This importer intentionally updates the LIVE Country table regardless of whether
        # it's called from live or staging import processes. Country relationships (parent-child)
        # are global metadata that should be consistent across all environments and don't need
        # staging table separation.
        OVERSEAS_TERRITORIES_CSV = "#{Rails.root}/lib/data/seeds/overseas_territories.csv"

        def self.update_live_table
          new.update_live_table
        end

        def update_live_table
          csv = CSV.read(OVERSEAS_TERRITORIES_CSV)
          csv.shift

          Rails.logger.info "Processing #{csv.length} parent-child relationships from CSV"

          imported_count = 0
          soft_errors = []
          relationships_created = {}
          info = {
            parent_country_not_found: [],
            child_country_not_found: [],
            already_added_so_skipped: 0
          }

          csv.each do |parent_iso, child_isos|
            # Wrap each parent-child relationship in its own transaction
            ActiveRecord::Base.transaction do
              parent_country = Country.find_by_iso_3(parent_iso)
              child_isos = child_isos.split(';')

              if parent_country.nil?
                Rails.logger.warn "Parent country not found: #{parent_iso}"
                info[:parent_country_not_found] << parent_iso
                next
              end

              child_isos.each do |child_iso|
                child_country = Country.find_by_iso_3(child_iso)

                if child_country.nil?
                  Rails.logger.warn "Child country not found: #{child_iso}"
                  info[:child_country_not_found] << child_iso
                  next
                end

                if parent_country.children.map(&:iso_3).include?(child_iso)
                  info[:already_added_so_skipped] += 1
                  next
                end

                parent_country.children << child_country

                relationships_created[parent_iso] ||= []
                relationships_created[parent_iso] << child_iso

                imported_count += 1
                Rails.logger.info "Added #{child_country.iso_3} to parent #{parent_country.iso_3}"
              rescue StandardError => e
                soft_errors << "Failed to process child country #{child_iso}: #{e.message}"
                Rails.logger.warn "Failed to process child country #{child_iso}: #{e.message}"
              end
            rescue StandardError => e
              soft_errors << "Failed to process parent country #{parent_iso}: #{e.message}"
              Rails.logger.warn "Failed to process parent country #{parent_iso}: #{e.message}"
            end
          end

          Rails.logger.info "Overseas territories import completed: #{imported_count} relationships created"
          if info[:parent_country_not_found].any?
            Rails.logger.info "info parent countries not found: #{info[:parent_country_not_found].join(', ')}"
          end
          if info[:child_country_not_found].any?
            Rails.logger.info "info child countries not found: #{info[:child_country_not_found].join(', ')}"
          end
          if relationships_created.any?
            Rails.logger.info "Relationships created: #{relationships_created.keys.join(', ')}"
          end

          Wdpa::Shared::ImporterBase::Base.success_result(:imported_count, soft_errors, [], {
            relationships_created: relationships_created,
            info: info
          })
        rescue StandardError => e
          Rails.logger.error "Overseas territories import failed: #{e.message}"
          Wdpa::Shared::ImporterBase::Base.failure_result("Import failed: #{e.message}", :imported_count, {
            relationships_created: {},
            info: {
              parent_country_not_found: [],
              child_country_not_found: []
            }
          })
        end
      end
    end
  end
end
