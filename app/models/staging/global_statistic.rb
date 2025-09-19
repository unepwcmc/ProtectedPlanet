module Staging
  class GlobalStatistic < ApplicationRecord
    self.table_name = 'staging_global_statistics'
    self.primary_key = 'id'
    validates_inclusion_of :singleton_guard, in: [0]
  end
end
