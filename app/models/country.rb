class Country < ActiveRecord::Base
  include GeometryConcern

  has_and_belongs_to_many :protected_areas

  has_one :country_statistic

  belongs_to :region
  belongs_to :region_for_index, -> { select("regions.id, regions.name") }, :class_name => "Region", :foreign_key => "region_id"

  has_many :sub_locations
  has_many :designations, -> { uniq }, through: :protected_areas
  has_many :iucn_categories, through: :protected_areas

  has_many :project_items, as: :item
  has_many :projects, through: :project_items

  def wdpa_ids
    protected_areas.map(&:wdpa_id)
  end

  def statistic
    country_statistic
  end

  def protected_areas_with_iucn_categories
    valid_categories = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"
    iucn_categories.where(
      "iucn_categories.name IN (#{valid_categories})"
    )
  end

  def self.data_providers
    joins(:protected_areas).uniq
  end

  def as_indexed_json options={}
    self.as_json(
      only: [:id, :name],
      include: {
        region_for_index: { only: [:id, :name] }
      }
    )
  end

  def random_protected_areas wanted=1
    random_offset = rand(protected_areas.count-wanted)
    protected_areas.offset(random_offset).limit(wanted)
  end

  def protected_areas_per_designation
    ActiveRecord::Base.connection.execute("""
      SELECT designations.name AS designation, pas_per_designations.count
      FROM designations
      INNER JOIN (
        #{protected_areas_inner_join(:designation_id)}
      ) AS pas_per_designations
        ON pas_per_designations.designation_id = designations.id
    """)
  end

  def protected_areas_per_iucn_category
    ActiveRecord::Base.connection.execute("""
      SELECT iucn_categories.name AS iucn_category, pas_per_iucn_categories.count
      FROM iucn_categories
      INNER JOIN (
        #{protected_areas_inner_join(:iucn_category_id)}
      ) AS pas_per_iucn_categories
        ON pas_per_iucn_categories.iucn_category_id = iucn_categories.id
    """)
  end

  private

  def protected_areas_inner_join group_by
    """
      SELECT #{group_by}, COUNT(protected_areas.id) AS count
      FROM protected_areas
      INNER JOIN countries_protected_areas
        ON protected_areas.id = countries_protected_areas.protected_area_id
        AND countries_protected_areas.country_id = #{self.id}
      GROUP BY #{group_by}
    """
  end
end
