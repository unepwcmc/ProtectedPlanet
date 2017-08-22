class CountryStatistic < ActiveRecord::Base
  belongs_to :country

  def national_percentage
    (pa_marine_area / marine_area) * 100
  end

  def overseas_total_area
    country.children.map(&:statistic).map(&:pa_marine_area).inject(0) do |sum, x|
      sum + (x || 0)
    end
  end

  def overseas_percentage
    (overseas_total_area / marine_area) * 100
  end
end
