module Staging
  class PameStatistic < ApplicationRecord
    self.table_name = 'staging_pame_statistics'
    self.primary_key = 'id'

    belongs_to :country
  end
end
