module Staging
  class CountryStatistic < ApplicationRecord
    self.table_name = 'staging_country_statistics'
    self.primary_key = 'id'
    belongs_to :country
  end
end
