class ProtectedArea < ActiveRecord::Base
  has_and_belongs_to_many :countries
  has_and_belongs_to_many :sub_locations
  has_and_belongs_to_many :sources

  has_many :images

  belongs_to :legal_status
  belongs_to :iucn_category
  belongs_to :governance
  belongs_to :management_authority
  belongs_to :no_take_status
  belongs_to :designation
  belongs_to :wikipedia_article

  after_create :create_slug

  scope :without_geometry, -> { select(self.column_names - ["the_geom"]) }

  def bounds
    [
      [bounding_box["min_y"], bounding_box["min_x"]],
      [bounding_box["max_y"], bounding_box["max_x"]]
    ]
  end

  private

  DB = ActiveRecord::Base.connection

  def bounding_box_query
    dirty_query = """
      SELECT ST_XMax(extent) AS max_x,
             ST_XMin(extent) AS min_x,
             ST_YMax(extent) AS max_y,
             ST_YMin(extent) AS min_y
      FROM (
        SELECT ST_Extent(pa.the_geom) AS extent
        FROM protected_areas pa
        WHERE wdpa_id = ?
      ) e
    """.squish

    ActiveRecord::Base.send(:sanitize_sql_array, [
      dirty_query, wdpa_id
    ])
  end

  def bounding_box
    @bounding_box ||= DB.execute(bounding_box_query).first
    @bounding_box.each { |key,str| @bounding_box[key] = str.to_f }
  end

  def create_slug
    updated_slug = [name, designation.try(:name)].join(' ').parameterize
    update_attributes(slug: updated_slug)
  end
end
