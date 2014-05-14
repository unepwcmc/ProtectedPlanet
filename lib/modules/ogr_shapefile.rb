require 'gdal-ruby/ogr'

class OgrShapefile
  SHAPEFILE_PARTS = ['shx', 'shp', 'dbf', 'prj']

  def split layer: layer, filename: filename, number_of_pieces: number_of_pieces
    @filename = filename
    @layer = layer
    @number_of_pieces = number_of_pieces

    limit = feature_count / number_of_pieces
    (0..number_of_pieces-1).each do |piece_index|
      shapefile_name = "#{layer}_#{piece_index}"
      offset = limit * piece_index

      ogr_command binding
    end
  end

  private

  def feature_count
    ogr_driver = Gdal::Ogr.open(@filename)
    layer = ogr_driver.get_layer(@layer)

    return layer.get_feature_count
  end

  def ogr_command context_binding
    template_path = File.join(Rails.root, 'lib', 'modules', 'ogr_shapefile_command.erb')
    template = File.read(template_path)

    system(ERB.new(template).result(context_binding).squish)
  end
end
