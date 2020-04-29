class CountryStatistic < ApplicationRecord
  belongs_to :country

  scope :top_marine_coverage, -> { order('percentage_pa_marine_cover DESC NULLS LAST').limit(6) }

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
    field_name = "#{type}_area"
    define_singleton_method("global_pa_#{field_name}") do
      _attr = "pa_#{field_name}"
      Stats::Global.calculate_stats_for(self, _attr)
    end

    define_singleton_method("global_#{field_name}") do
      Stats::Global.calculate_stats_for(self, field_name)
    end

    define_singleton_method("global_percentage_pa_#{type}_cover") do
      (public_send("global_pa_#{field_name}") / public_send("global_#{field_name}") * 100).round(2)
    end
  end
end
