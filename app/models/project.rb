class Project < ActiveRecord::Base
  include PolymorphicGroup

  belongs_to :user

  has_many :project_items

  has_many :protected_areas, through: :project_items, source: :item, source_type: 'ProtectedArea'
  has_many :countries, through: :project_items, source: :item, source_type: 'Country'
  has_many :regions, through: :project_items, source: :item, source_type: 'Region'
  has_many :saved_searches

  polymorphic_group :items, [:protected_areas, :countries, :regions, :saved_searches]

  def download_link type
    $redis.get("project_#{id}_all")
  end
end
