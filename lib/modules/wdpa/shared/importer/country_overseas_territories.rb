# frozen_string_literal: true

require 'csv'

module Wdpa::Shared::Importer
  class CountryOverseasTerritories
    # NOTE: This importer intentionally updates the LIVE Country table regardless of whether
    # it's called from live or staging import processes. Country relationships (parent-child)
    # are global metadata that should be consistent across all environments and don't need
    # staging table separation.
    OVERSEAS_TERRITORIES_CSV = "#{Rails.root}/lib/data/seeds/overseas_territories.csv".freeze

    def self.update_live_table
      new.update_live_table
    end

    def update_live_table
      csv = CSV.read(OVERSEAS_TERRITORIES_CSV)
      csv.shift

      results = {
        success: true,
        imported_count: 0,
        errors: [],
        relationships_created: {},
        skipped: []
      }

      ActiveRecord::Base.transaction do
        csv.each do |parent_iso, child_isos|
          parent_country = Country.find_by_iso_3(parent_iso)
          child_isos = child_isos.split(';')

          if parent_country.nil?
            results[:skipped] << "Parent country not found: #{parent_iso}"
            next
          end

          child_isos.each do |child_iso|
            child_country = Country.find_by_iso_3(child_iso)

            if child_country.nil?
              results[:skipped] << "Child country not found: #{child_iso}"
              next
            end

            if parent_country.children.map(&:iso_3).include?(child_iso)
              results[:skipped] << "Relationship already exists: #{child_iso} -> #{parent_iso}"
              next
            end

            parent_country.children << child_country

            results[:relationships_created][parent_iso] ||= []
            results[:relationships_created][parent_iso] << child_iso

            results[:imported_count] += 1
            Rails.logger.info "Added #{child_country.iso_3} to parent #{parent_country.iso_3}"
          end
        end
      end

      Rails.logger.info "Overseas territories import completed: #{results[:imported_count]} relationships created"
      results
    rescue StandardError => e
      Rails.logger.error "Overseas territories import failed: #{e.message}"
      {
        success: false,
        imported_count: 0,
        errors: ["Import failed: #{e.message}"],
        relationships_created: {},
        skipped: []
      }
    end
  end
end
