class StagingGreenListStatus < ApplicationRecord
   
   self.table_name = "staging_green_list_statuses"

   has_one :protected_area, class_name: 'StagingProtectedArea'

   validates :status, uniqueness: { scope: :expiry_date }
end