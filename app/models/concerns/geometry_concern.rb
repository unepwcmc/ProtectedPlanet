module GeometryConcern
 extend ActiveSupport::Concern

  included do
    scope :without_geometry, -> { select(column_names - self.geometry_columns) }
  end

  module ClassMethods
    def geometry_columns
      columns_hash.select { |_,v| v.type == :spatial }.keys
    end
  end

  def bounds
    rgeo_factory = RGeo::Geos.factory srid: 4326
    bounds = RGeo::Cartesian::BoundingBox.new rgeo_factory
    bounds.add bounding_box

    [
      [bounds.min_y, bounds.min_x],
      [bounds.max_y, bounds.max_x]
    ]
  end

  def geojson
    ActiveRecord::Base.connection.select_value("""
      SELECT ST_AsGeoJSON(ST_SimplifyPreserveTopology(#{main_geom_column}, 0.003), 3)
      FROM #{self.class.table_name}
      WHERE id = #{id}
    """.squish)
  end

  private

  def main_geom_column
    self.respond_to?(:the_geom) ? 'the_geom' : 'bounding_box'
  end
end
