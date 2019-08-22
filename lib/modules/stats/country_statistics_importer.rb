module Stats::CountryStatisticsImporter
  def self.import
    import_stats(stats_csv_path, CountryStatistic)
    import_stats(pame_csv_path,  PameStatistic)
    import_stats(aichi11_target_csv_path, Aichi11Target)
  end

  def self.import_stats path, model
    countries = Country.pluck(:id, :iso_3).each_with_object({}) { |(id, iso_3), hash|
      hash[iso_3] = id
    }

    CSV.foreach(path, headers: true) do |row|
      country_iso3 = row.delete('iso3').last
      # If the value is na (not applicable) use nil
      row.each { |key, value| row[key] = nil if value && value.downcase == 'na' }
      attrs = {country_id: countries[country_iso3]}.merge(row)

      model.create(attrs)
    end
  end

  def self.stats_csv_path
    Rails.root.join('lib/data/seeds/country_statistics.csv')
  end

  def self.pame_csv_path
    Rails.root.join('lib/data/seeds/pame_country_stats.csv')
  end

  def self.aichi11_target_csv_path
    Rails.root.join('lib/data/seeds/aichi11_targets.csv')
  end
end
