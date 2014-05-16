class Shapefile
  attr_accessor :path

  SHAPEFILE_PARTS = ['shx', 'shp', 'dbf', 'prj']

  def initialize path
    @path = path
  end

  def filename
    File.basename(@path, File.extname(@path))
  end

  def components
    SHAPEFILE_PARTS.collect do |ext|
      "#{path_without_extension}.#{ext}"
    end
  end

  def compress
    zip_file = "#{path_without_extension}.zip"
    system("zip #{zip_file} #{components.join(" ")}")

    return zip_file
  end

  private
 
  def path_without_extension
    File.join(File.dirname(@path), "#{filename}")
  end
end
