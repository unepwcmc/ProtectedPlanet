class CountryStatistic < ActiveRecord::Base
  belongs_to :country

  def overseas_total_area
    country.children.map(&:statistic).map(&:pa_marine_area).inject(0) do |sum, x|
      sum + (x || 0)
    end
  end

  def overseas_percentage
    (pa_marine_area / overseas_total_area) * 100
  end
end
