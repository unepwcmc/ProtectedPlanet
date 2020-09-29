class CountryStatistic < ApplicationRecord
  belongs_to :country

  scope :top_marine_coverage, -> { order('percentage_pa_marine_cover DESC NULLS LAST').limit(6) }

  def total_marine_area
    marine_area + overseas_total_marine_area
  end

  def total_protected_marine_area
    pa_marine_area + overseas_total_protected_marine_area
  end

  def total_area
    land_area + marine_area
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

  [:pa, :oecms_pa].each do |pa_type|
    [:land, :marine].each do |type|
      field_name = "#{type}_area"
      define_singleton_method("global_#{pa_type}_#{field_name}") do
        attr = "#{pa_type}_#{field_name}"
        Stats::Global.calculate_stats_for(self, attr)
      end

      define_singleton_method("global_#{field_name}") do
        Stats::Global.calculate_stats_for(self, field_name)
      end

      define_singleton_method("global_percentage_#{pa_type}_#{type}_cover") do
        (public_send("global_#{pa_type}_#{field_name}") / public_send("global_#{field_name}") * 100).round(2)
      end
    end
  end
end
