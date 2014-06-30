require 'gdal-ruby/ogr'

class Ogr::Split
  def self.split filename, layer, number_of_pieces, column_names = ['*']
    splitter = new(filename, layer, column_names)
    splitter.split number_of_pieces
  end

  def initialize filename, layer, column_names
    @filename = filename
    @layer = layer
    @column_names = column_names
  end

  def split number_of_pieces
    limit = feature_count / number_of_pieces

    (0..number_of_pieces-1).collect do |piece_index|
      shapefile_name = "#{@layer}_#{piece_index}"
      new_shapefile_path = File.join(File.dirname(@filename), "#{shapefile_name}.shp")
      offset = limit * piece_index

      Ogr::Shapefile.convert_with_query(
        @filename, new_shapefile_path,
        query(limit, offset)
      )

      new_shapefile_path
    end
  end

  private

  def query limit, offset
    "SELECT #{@column_names.join(',')} FROM #{@layer} LIMIT #{limit} OFFSET #{offset}"
  end

  def feature_count
    ogr_info = Ogr::Info.new @filename
    ogr_info.feature_count @layer
  end
end
