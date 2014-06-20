class Ogr::Postgres
  WRONG_ARGUMENTS_MSG = 'Given new table name, but no original table name'
  DB_CONFIG = Rails.configuration.database_configuration[Rails.env]

  DRIVERS = {
    shapefile: 'ESRI Shapefile',
    csv:       'CSV',
    kml:       'KML'
  }

  TEMPLATE_DIRECTORY = File.join(File.dirname(__FILE__), 'command_templates')
  TEMPLATES = {
    import: File.read(File.join(TEMPLATE_DIRECTORY, 'postgres_import.erb')),
    export: File.read(File.join(TEMPLATE_DIRECTORY, 'postgres_export.erb')),
  }

  def self.import file_path, original_table_name=nil, table_name=nil
    if table_name && !original_table_name
      raise ArgumentError, WRONG_ARGUMENTS_MSG
    end

    system ogr_command(TEMPLATES[:import], binding)
  end

  def self.export file_type, file_name, query
    system ogr_command(TEMPLATES[:export], binding)
  end

  private

  def self.ogr_command template, context
    compiled_template = ERB.new(template).result context
    compiled_template.squish
  end
end
