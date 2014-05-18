class Ogr::Shapefile
  TEMPLATE_PATH = File.join(File.dirname(__FILE__), 'ogr_shapefile_command.erb')

  def self.convert_with_query filename, new_filename, query
    options = {
      query: query
    }

    run filename, new_filename, options
  end

  private

  def self.run filename, new_filename, options
    template = ERB.new(File.read(TEMPLATE_PATH))
    system(template.result(binding).squish)
  end
end
