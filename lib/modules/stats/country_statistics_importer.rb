module Stats::CountryStatisticsImporter
  def self.import
    import_stats
    import_pame
  end

  def self.import_stats
    CSV.foreach(stats_csv_path, headers: true) do |row|
      CountryStatistic.create(row.to_h)
    end
  end

  def self.import_pame
    countries = Country.pluck(:id, :iso_3).each_with_object({}) { |(id, iso_3), hash|
      hash[iso_3] = id
    }

    CSV.foreach(pame_csv_path, headers: true) do |row|
      country_iso3 = row.delete('iso3').last
      attrs = {country_id: countries[country_iso3]}.merge(row)

      PameStatistic.create(attrs)
    end
  end

  def self.stats_csv_path
    Rails.root.join('lib/data/seeds/country_statistics.csv')
  end

  def self.pame_csv_path
    Rails.root.join('lib/data/seeds/pame_country_stats.csv')
  end
end
