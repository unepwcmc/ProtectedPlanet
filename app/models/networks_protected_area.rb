class NetworksProtectedArea < ActiveRecord::Base
  belongs_to :network
  belongs_to :protected_area
end
