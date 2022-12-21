module GeometryConcern
 extend ActiveSupport::Concern

  included do
    scope :without_geometry, -> { select(column_names - self.geometry_columns) }
  end

  module ClassMethods
    def geometry_columns
      columns_hash.select { |_,v| v.type == :geometry }.keys
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

  def geojson_for_mapbox_uri geo_properties=nil
    # Returns a stringified geojson for making a request to the Mapbox API, to generate a preview thumbnail.
    # If the string is too long it will be rejected, so we then need to simplify it.
    # We fall back on a convex transformation, which provides a very crude outline, but is a short string.
    geojson = geojson_query(geo_properties)
    if geojson_suitable_for_mapbox_url?(geojson)
      geojson
    else
      convex_geojson_query(geo_properties)
    end
  end

  def geojson_suitable_for_mapbox_url?(geojson)
    geojson.present? && geojson.length <= 5000
  end

  def geojson geo_properties=nil
    geojson_query(geo_properties)
  end

  private

  def convex_geojson_query geo_properties
    # Very simple polygon, if other polygon thumbnail methods fail.
    simplified_geojson = ActiveRecord::Base.connection.select_value("""
    SELECT ST_AsGeoJSON(ST_ConvexHull(ST_MakeValid(#{main_geom_column})), 3)
      FROM #{self.class.table_name}
      WHERE id = #{id}
    """.squish)

    simplified_geojson.present? ? to_uri(simplified_geojson, geo_properties) : nil
  end

  def geojson_query(geo_properties)
    simplified_geojson = ActiveRecord::Base.connection.select_value("""
    SELECT ST_AsGeoJSON(ST_SimplifyPreserveTopology(ST_MakeValid(#{main_geom_column}), 0.003), 3)
      FROM #{self.class.table_name}
      WHERE id = #{id}
    """.squish)

    simplified_geojson.present? ? to_uri(simplified_geojson, geo_properties) : nil
  end

  def to_uri(geojson, geo_properties=nil)
    geometry = JSON.parse(geojson)

    URI.encode({
      "type" => "Feature",
      "properties" => geo_properties || geometry_properties,
      "geometry" => geometry
    }.to_json)
  end

  def geometry_properties
    if self.respond_to?(:marine) && marine
      {
        "fill-opacity" => 0.7,
        "stroke-width" => 0.05,
        "stroke" => "#2E5387",
        "fill" => "#3E7BB6",
        "marker-color" => "#2B3146"
      }
    else
      {
        "fill-opacity" => 0.7,
        "stroke-width" => 0.05,
        "stroke" => "#40541b",
        "fill" => "#83ad35",
        "marker-color" => "#2B3146"
      }
    end
  end

  def main_geom_column
    self.respond_to?(:the_geom) ? 'the_geom' : 'bounding_box'
  end
end
