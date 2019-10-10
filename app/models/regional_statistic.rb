class RegionalStatistic < ApplicationRecord
  self.table_name = 'regional_statistics_view'
  belongs_to :region
end
