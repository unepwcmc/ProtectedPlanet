module Staging
  class GreenListStatus < ApplicationRecord
    self.table_name = 'staging_green_list_statuses'
    self.primary_key = 'id'
    
    has_one :protected_area, class_name: 'Staging::ProtectedArea'
    has_one :protected_area_parcel, class_name: 'Staging::ProtectedAreaParcel'
  end
end
