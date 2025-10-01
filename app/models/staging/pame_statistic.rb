module Staging
  class PameStatistic < ApplicationRecord
    self.table_name = 'staging_pame_statistics'
    self.primary_key = 'id'

    belongs_to :country

    # [:land, :marine].each do |type|
    #   field_name = "pame_pa_#{type}_area"
    #   define_singleton_method("global_#{field_name}") do
    #     Stats::Global.calculate_stats_for(self, field_name)
    #   end

    #   total_area = CountryStatistic.public_send("global_#{type}_area")
    #   define_singleton_method("global_pame_percentage_pa_#{type}_cover") do
    #     (public_send("global_#{field_name}") / total_area * 100).round(2)
    #   end
    # end
  end
end
