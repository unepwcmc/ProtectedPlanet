class OgrShapefile
  TEMPLATE_PATH = File.join(Rails.root, 'lib', 'modules', 'ogr_shapefile_command.erb')

  def initialize input_file
    @input_file = input_file
  end

  def convert_with_query query, filename
    options = {
      query: query
    }

    run filename, options
  end

  private

  def run new_file, options
    shapefile = Shapefile.new new_file

    template = ERB.new(File.read(TEMPLATE_PATH))
    system(template.result(binding).squish)

    return shapefile.compress
  end
end
