# Todo: to be removed as network is no longer being used
class NetworksProtectedArea < ApplicationRecord
  belongs_to :network
  belongs_to :protected_area
end
