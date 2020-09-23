class GlobalStatistic < ApplicationRecord
  validates_inclusion_of :singleton_guard, :in => [0]

  def self.instance
    first_or_create!(singleton_guard: 0)
  end

  MARINE_STATS = %w(
    total_marine_protected_areas
    total_ocean_pa_coverage_percentage
    total_ocean_area_protected
    national_waters_pa_coverage_percentage
    national_waters_pa_coverage_area
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
end