class PameStatistic < ApplicationRecord
  belongs_to :country

  [:land, :marine].each do |type|
    field_name = "pame_percentage_pa_#{type}_cover"
    define_singleton_method("global_#{field_name}") do
      stats = where.not(country_id: nil)
      sum =
        stats.map(&field_name.to_sym).inject(0) do |_sum, x|
          _sum + (x || 0)
        end
      (sum / Country.count).round(2)
    end
  end
end
