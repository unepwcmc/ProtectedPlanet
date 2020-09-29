module Wdpa::GlobalStatsImporter
  extend self

  GLOBAL_STATS_CSV = Rails.root.join('lib/data/seeds/global_stats.csv').freeze

  def self.import
    GlobalStatistic.first.destroy
    
    attrs = {singleton_guard: 0}
    CSV.foreach(GLOBAL_STATS_CSV, headers: true) do |row|
      field = row['type']
      value = parse_value(row['value'])
      attrs.merge!("#{field}": value)
    end

    GlobalStatistic.create(attrs)
  end

  private

  # If it's a string, ensure to remove commas before casting to float.
  # If it's a float this will basically return the value as it is in the csv.
  # Even though strings in the csv are mostly integers, converting it to float here
  # shouldn't cause issues with the database where the field is explicitly an integer.
  # Postgres should take care of it.
  def self.parse_value(val)
    val.to_s.split(',').join('').to_f
  end
end