module Staging
  class CountryStatistic < ApplicationRecord
    self.table_name = 'staging_country_statistics'
    belongs_to :country
  end
end
