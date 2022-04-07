# frozen_string_literal: true

module Stats::CountryStatisticsImporter
  def self.latest_country_statistics_csv
    ::Utilities::Files.latest_file_by_glob('lib/data/seeds/country_statistics_*.csv')
  end

  def self.latest_pame_country_statistics_csv
    ::Utilities::Files.latest_file_by_glob('lib/data/seeds/pame_country_statistics_*.csv')
  end

  def self.import
    import_stats(latest_country_statistics_csv, CountryStatistic)
    import_stats(latest_pame_country_statistics_csv, PameStatistic)

    # Import stats from DOPA services
    # Stats::CountryStatisticsApi.import

    # Import Aichi11Target stats from CSV
    Aichi11Target.instance
  end

  def self.import_stats(path, model)
    countries = Country.pluck(:id, :iso_3).each_with_object({}) do |(id, iso_3), hash|
      hash[iso_3] = id
    end

    CSV.foreach(path, headers: true) do |row|
      country_iso3 = row.delete('iso3').last
      country_id = countries[country_iso3]
      # If the value is na (not applicable) use nil
      row.each { |key, value| row[key] = nil if value && value.downcase == 'na' }
      attrs = { country_id: country_id }.merge(row)
      attrs = attrs.merge(pame_assessments(country_id)) if model == PameStatistic

      model.create(attrs)
    end
  end

  def self.pame_assessments(country_id)
    return {} unless country_id

    country = Country.find(country_id)

    {
      assessments: country.assessments,
      assessed_pas: country.assessed_pas
    }
  end
end
