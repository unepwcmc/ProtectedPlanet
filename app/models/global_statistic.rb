require 'csv'

class GlobalStatistic < ApplicationRecord
  self.table_name = 'global_statistics'

  validates_inclusion_of :singleton_guard, :in => [0]

  def self.instance
    first_or_create!(singleton_guard: 0)
  end

  MARINE_STATS = %w(
    total_marine_protected_areas
    total_marine_oecms
    total_marine_oecms_pas
    total_ocean_pa_coverage_percentage
    total_ocean_oecms_pas_coverage_percentage
    total_ocean_area_protected
    total_ocean_area_oecms_pas
    national_waters_pa_coverage_percentage
    national_waters_oecms_pas_coverage_percentage
    national_waters_pa_coverage_area
    national_waters_oecms_pas_coverage_area
    high_seas_pa_coverage_percentage
    high_seas_pa_coverage_area
    national_waters_percentage
    global_ocean_percentage
  ).freeze
  def self.marine_stats
    instance.slice(*MARINE_STATS)
  end

  GREEN_LIST_STATS = %w(
    green_list_perc
    green_list_area
    green_list_count
  ).freeze
  def self.green_list_stats
    instance.slice(*GREEN_LIST_STATS)
  end

  self.column_names.each do |column_name|
    define_singleton_method(column_name) do
      self.instance.send(column_name)
    end
  end

  DESCRIPTIONS_CSV_PATH = Rails.root.join('lib/data/seeds/global_stats_descriptions.csv')

  # Values always come from this record (whichever import source populated it), so the
  # download can never drift from what's rendered on the site. Descriptions (including
  # the trailing methodology note, which has a blank type) live in their own file since
  # they aren't stored on this table and change far less often than values.
  def self.download_csv
    record = instance
    Rails.cache.fetch(download_csv_cache_key(record)) { generate_download_csv(record) }
  end

  def self.download_csv_cache_key(record)
    "global_statistics_download_csv/#{record.updated_at.to_f}/#{File.mtime(DESCRIPTIONS_CSV_PATH).to_f}"
  end
  private_class_method :download_csv_cache_key

  def self.generate_download_csv(record)
    CSV.generate(headers: true) do |csv|
      csv << %w(type description value)
      CSV.foreach(DESCRIPTIONS_CSV_PATH, headers: true) do |row|
        value = row['type'].present? ? record[row['type']] : nil
        csv << [row['type'], row['description'], value]
      end
    end
  end
  private_class_method :generate_download_csv

  def self.download_csv_filename
    "global_statistics_#{Date.parse(Release.current_label).strftime('%Y-%m-01')}.csv"
  rescue TypeError, ArgumentError
    "global_statistics.csv"
  end
end