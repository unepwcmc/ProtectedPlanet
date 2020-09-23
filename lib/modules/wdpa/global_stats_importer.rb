module Wdpa::GlobalStatsImporter
  extend self

  GLOBAL_STATS_CSV = Rails.root.join('lib/data/seeds/global_stats.csv').freeze

  def self.import
    attrs = {singleton_guard: 0}
    CSV.foreach(GLOBAL_STATS_CSV, headers: true) do |row|
      field = row['type']
      value = parse_value(row['value'])
      attrs.merge!("#{field}": value)
    end

    puts attrs
    GlobalStatistic.create(attrs)
  end

  private

  def self.parse_value(val)
    val.to_s.split(',').join('').to_f
  end
end