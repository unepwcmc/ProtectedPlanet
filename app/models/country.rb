class Country < ActiveRecord::Base
  include GeometryConcern

  has_and_belongs_to_many :protected_areas
  has_one :country_statistic

  has_many :sub_locations
  belongs_to :region

  def as_indexed_json options={}
    self.as_json(
      only: [:name],
      include: {
        region: { only: [:id, :name] }
      }
    )
  end
end
