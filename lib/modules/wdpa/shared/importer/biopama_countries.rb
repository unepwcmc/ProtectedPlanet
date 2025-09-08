# frozen_string_literal: true

# As of 05Sep2025 it might not used check with NC for confirmation
module Wdpa
  module Shared
    module Importer
      class BiopamaCountries
        # NOTE: This importer intentionally updates the LIVE Country table regardless of whether
        # it's called from live or staging import processes. BIOPAMA country flags are global
        # metadata that should be consistent across all environments and don't need staging
        # table separation.
        BIOPAMA_COUNTRIES_CSV = "#{Rails.root}/lib/data/seeds/biopama_countries_iso_codes.csv"

        def self.update_live_table
          begin
            countries_updated = 0
            countries_not_found = 0
            soft_errors = []

            csv = CSV.read(BIOPAMA_COUNTRIES_CSV)
            csv.shift # remove headers

            csv.each do |row|
              # Wrap each row in its own transaction to prevent batch failure
              ActiveRecord::Base.transaction do
                next if row[0].blank?

                iso = row[0].strip
                country = Country.find_by_iso_3(iso)

                if country
                  country.update_attributes(is_biopama: true)
                  countries_updated += 1
                else
                  countries_not_found += 1
                  Rails.logger.warn "Country with ISO code #{iso} does not exist"
                end
              end
            rescue StandardError => e
              soft_errors << "Failed to process country #{row[0]}: #{e.message}"
              Rails.logger.warn "Failed to process country #{row[0]}: #{e.message}"
            end

            Rails.logger.info "BIOPAMA countries import completed: #{countries_updated} updated, #{countries_not_found} not found"

            {
              success: true,
              soft_errors: soft_errors,
              hard_errors: [],
              countries_updated: countries_updated,
              countries_not_found: countries_not_found
            }
          rescue StandardError => e
            Rails.logger.error "BIOPAMA countries import failed: #{e.message}"
            {
              success: false,
              soft_errors: [],
              hard_errors: ["Import failed: #{e.message}"],
              countries_updated: 0,
              countries_not_found: 0
            }
          end
        end
      end
    end
  end
end
