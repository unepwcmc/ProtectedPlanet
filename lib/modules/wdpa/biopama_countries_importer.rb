module Wdpa::BiopamaCountriesImporter
  BIOPAMA_COUNTRIES_CSV = "#{Rails.root}/lib/data/seeds/biopama_countries_iso_codes.csv"
  extend self

  def import
    ActiveRecord::Base.transaction do
      csv = CSV.read(BIOPAMA_COUNTRIES_CSV)
      csv.shift # remove headers

      csv.each do |row|
        iso = row[0]
        country = Country.find_by_iso_3(iso)
        if country
          country.update_attributes(is_biopama: true)
          puts "#{country.name} has been flagged as BIOPAMA country"
        else
          puts "Country with iso_3 #{iso} does not exist"
        end
      end
    end
  end
end
