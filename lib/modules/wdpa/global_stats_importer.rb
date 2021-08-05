# frozen_string_literal: true

module Wdpa::GlobalStatsImporter
  def self.latest_global_stats_csv
    ::Utilities::Files.latest_file_by_glob('lib/data/seeds/global_stats_*.csv')
  end

  def self.import
    attrs = { singleton_guard: 0 }
    CSV.foreach(latest_global_stats_csv, headers: true) do |row|
      field = row['type']
      value = parse_value(row['value'])
      attrs.merge!("#{field}": value)
    end

    stats = GlobalStatistic.first_or_initialize(attrs)
    stats.update(attrs)
  end

  # If it's a string, ensure to remove commas before casting to float.
  # If it's a float this will basically return the value as it is in the csv.
  # Even though strings in the csv are mostly integers, converting it to float here
  # shouldn't cause issues with the database where the field is explicitly an integer.
  # Postgres should take care of it.
  def self.parse_value(val)
    val.to_s.split(',').join('').to_f
  end
end
