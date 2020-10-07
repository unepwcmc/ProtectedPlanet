#  TODO: To be removed at a later date - because networks are no longer being used
#  to determine whether a protected area is transboundary

class Network < ApplicationRecord
  has_many :networks_protected_areas, dependent: :destroy
  has_many :protected_areas, through: :networks_protected_areas

  def bounds
    [
      [bounding_box["min_y"], bounding_box["min_x"]],
      [bounding_box["max_y"], bounding_box["max_x"]]
    ]
  end

  def countries
    protected_areas.map(&:countries).flatten.uniq
  end

  private

  def bounding_box_query
    dirty_query = """
      SELECT ST_XMax(extent) AS max_x,
             ST_XMin(extent) AS min_x,
             ST_YMax(extent) AS max_y,
             ST_YMin(extent) AS min_y
      FROM (
        SELECT ST_Extent(pa.the_geom) AS extent
        FROM protected_areas pa
        WHERE wdpa_id IN (?)
      ) e
    """.squish

    ActiveRecord::Base.send(:sanitize_sql_array, [
      dirty_query, protected_areas.pluck(:wdpa_id)
    ])
  end

  def bounding_box
    @bounding_box ||= db.execute(bounding_box_query).first
    @bounding_box.each { |key,str| @bounding_box[key] = str.to_f }
  end

  def db
    ActiveRecord::Base.connection
  end

end
