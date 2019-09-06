class CountryStatistic < ApplicationRecord
  belongs_to :country

  def national_percentage
    (pa_marine_area / marine_area) * 100
  end

  def total_marine_area
    marine_area + overseas_total_marine_area
  end

  def total_protected_marine_area
    pa_marine_area + overseas_total_protected_marine_area
  end

  def overseas_total_protected_marine_area
    country.children.map(&:statistic).map(&:pa_marine_area).inject(0) do |sum, x|
      sum + (x || 0)
    end
  end

  def overseas_total_marine_area
    country.children.map(&:statistic).map(&:marine_area).inject(0) do |sum, x|
      sum + (x || 0)
    end
  end

  def overseas_percentage
    (overseas_total_protected_marine_area / overseas_total_marine_area) * 100
  end

  [:land, :marine].each do |type|
    field_name = "percentage_pa_#{type}_cover"
    define_singleton_method("global_#{field_name}") do
      Stats::Global.calculate_stats_for(self, field_name)
    end
  end

  [:well_connected, :importance].each do |field|
    field_name = "percentage_#{field}"
    define_singleton_method("global_#{field_name}") do
      Stats::Global.calculate_stats_for(self, field_name)
    end
  end
end
