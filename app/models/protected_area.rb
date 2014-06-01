class ProtectedArea < ActiveRecord::Base
  has_and_belongs_to_many :countries
  has_and_belongs_to_many :sub_locations

  belongs_to :legal_status
  belongs_to :iucn_category
  belongs_to :governance
end
