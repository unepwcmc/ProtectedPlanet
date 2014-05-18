require 'gdal-ruby/ogr'

class Ogr::Split
  def split filename, layer, number_of_pieces
    @filename = filename
    @layer = layer

    limit = feature_count / number_of_pieces

    (0..number_of_pieces-1).collect do |piece_index|
      shapefile_name = "#{layer}_#{piece_index}"
      new_shapefile_path = File.join(File.dirname(@filename), "#{shapefile_name}.shp")
      offset = limit * piece_index

      Ogr::Shapefile.convert_with_query(
        filename, new_shapefile_path,
        query(limit, offset)
      )

      new_shapefile_path
    end
  end

  private

  def query limit, offset
    "SELECT * FROM #{@layer} LIMIT #{limit} OFFSET #{offset}"
  end

  def feature_count
    ogr_driver = Gdal::Ogr.open(@filename)
    layer = ogr_driver.get_layer(@layer)

    return layer.get_feature_count
  end
end
