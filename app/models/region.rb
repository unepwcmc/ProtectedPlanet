class Region < ActiveRecord::Base
  include GeometryConcern

  has_many :countries
  has_many :protected_areas, through: :countries
  has_many :designations, -> { uniq }, through: :protected_areas
  has_many :iucn_categories, through: :protected_areas

  has_one :regional_statistic

  def wdpa_ids
    protected_areas.map(&:wdpa_id)
  end

  def statistic
    regional_statistic
  end

  def countries_providing_data
    countries.joins(:protected_areas).uniq
  end

  def protected_areas_with_iucn_categories
    valid_categories = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"
    iucn_categories.where(
      "iucn_categories.name IN (#{valid_categories})"
    )
  end

  def as_indexed_json options={}
    self.as_json(
      only: [:id, :name]
    )
  end

  def protected_areas_per_designation(jurisdiction=nil)
    ActiveRecord::Base.connection.execute("""
      SELECT designations.id AS designation_id, designations.name AS designation_name, pas_per_designations.count
      FROM designations
      INNER JOIN (
        #{protected_areas_inner_join(:designation_id)}
      ) AS pas_per_designations
        ON pas_per_designations.designation_id = designations.id
      #{"WHERE designations.jurisdiction_id = #{jurisdiction.id}" if jurisdiction}
    """)
  end

  private

  def protected_areas_inner_join group_by
    """
      SELECT #{group_by}, COUNT(protected_areas.id) AS count
      FROM protected_areas
      INNER JOIN countries_protected_areas
        ON protected_areas.id = countries_protected_areas.protected_area_id
        AND countries_protected_areas.country_id IN (#{self.countries.pluck(:id).join(",")})
      GROUP BY #{group_by}
    """
  end
end
