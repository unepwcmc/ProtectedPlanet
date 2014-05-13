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
			zip_command shapefile_name
		end
	end

	private

	def feature_count
		ogr_driver = Gdal::Ogr.open(@filename)
 		layer = ogr_driver.get_layer(@layer)

 		return layer.get_feature_count
	end

	def zip_command filename
		zip_command = ["zip #{filename}.zip"]

		SHAPEFILE_PARTS.each do |part|
			zip_command.push "#{filename}.#{part}"
		end

		system(zip_command.join(" "))

		File.delete(*zip_command.drop(1))
	end

	def ogr_command context_binding
    template_path = File.join(Rails.root, 'lib', 'modules', 'ogr_shapefile_command.erb')
    template = File.read(template_path)

    system(ERB.new(template).result(context_binding).squish)
  end
end