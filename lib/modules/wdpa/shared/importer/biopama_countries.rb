module Wdpa::Shared::Importer
  class BiopamaCountries
    BIOPAMA_COUNTRIES_CSV = "#{Rails.root}/lib/data/seeds/biopama_countries_iso_codes.csv"

    def self.import
      countries_updated = 0
      countries_not_found = 0

      ActiveRecord::Base.transaction do
        csv = CSV.read(BIOPAMA_COUNTRIES_CSV)
        csv.shift # remove headers

        csv.each do |row|
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
      end

      Rails.logger.info "BIOPAMA countries import completed: #{countries_updated} updated, #{countries_not_found} not found"

      {
        success: true,
        countries_updated: countries_updated,
        countries_not_found: countries_not_found
      }
    end
  end
end
