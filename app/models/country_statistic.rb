class CountryStatistic < ApplicationRecord
  belongs_to :country

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
end
