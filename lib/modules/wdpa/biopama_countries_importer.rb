module Wdpa::BiopamaCountriesImporter
  BIOPAMA_COUNTRIES_CSV = "#{Rails.root}/lib/data/seeds/biopama_countries.csv"
  extend self

  def import
    ActiveRecord::Base.transaction do
      CSV.foreach(BIOPAMA_COUNTRIES_CSV, headers: true) do |row|
        iso = row['iso3']
        region = row['acp_region']
        country = Country.find_by_iso_3(iso)
        if country
          country.update_attributes(acp_region: region)
          puts "#{country.name} has been flagged as an ACP country"
        else
          puts "Country with iso_3 #{iso} does not exist"
        end
      end
    end
  end
end
