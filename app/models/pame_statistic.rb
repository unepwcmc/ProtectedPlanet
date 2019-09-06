class PameStatistic < ApplicationRecord
  belongs_to :country

  [:land, :marine].each do |type|
    field_name = "pame_percentage_pa_#{type}_cover"
    define_singleton_method("global_#{field_name}") do
      Stats::Global.calculate_stats_for(self, field_name)
    end
  end
end
