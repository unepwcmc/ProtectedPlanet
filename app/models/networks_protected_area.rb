class NetworksProtectedArea < ApplicationRecord
  belongs_to :network
  belongs_to :protected_area
end
