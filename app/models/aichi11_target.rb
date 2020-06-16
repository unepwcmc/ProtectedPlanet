class Aichi11Target < ActiveRecord::Base
  validates_inclusion_of :singleton_guard, :in => [0]

  ATTRIBUTES = {
    representative: 'Representative',
    well_connected: 'Well connected',
    importance: 'Areas of importance for biodiversity'
  }.freeze

  def self.instance
    first || import
  end

  # Refresh representative, well_connected and importance values
  # by fetching data again from the API
  def self.refresh_values
    obj = first
    unless obj
      import
      return
    end
    obj.update_attributes(Stats::CountryStatisticsApi.global_stats_for_import)
  end

  def self.import
    # Import representative, well_connected and importance values from API
    global_values = Stats::CountryStatisticsApi.global_stats_for_import
    global_values = {} if global_values.is_a?(Array)
    # Import targets from file
    CSV.foreach(aichi11_target_csv_path, headers: true) do |row|
      return create({}.merge(row).merge(global_values))
    end
  end

  def self.aichi11_target_csv_path
    Rails.root.join('lib/data/seeds/aichi11_targets.csv')
  end

  private_class_method :import, :aichi11_target_csv_path
end
