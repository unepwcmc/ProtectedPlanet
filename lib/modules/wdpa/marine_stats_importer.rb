module Wdpa::MarineStatsImporter
  extend self

  def self.import
    import_stats(stats_csv_path)
  end

  def self.import_stats path
    stats = {}
    CSV.foreach(path, headers: true) do |row|
      value = row["value"].tr(',', '')
      stats[row["type"]] = value
      $redis.hmset('wdpa_marine_stats', row["type"], value)
    end
    stats
  end

  def self.stats_csv_path
    Rails.root.join('lib/data/seeds/marine_statistics.csv')
  end
end
