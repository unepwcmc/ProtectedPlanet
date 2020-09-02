class Ogr::Postgres
  class ExportError < StandardError; end;

  WRONG_ARGUMENTS_MSG = 'Given new table name, but no original table name'
  DRIVERS = {
    shapefile: 'ESRI Shapefile',
    csv:       'CSV',
    gdb:       'FileGDB'
  }

  TEMPLATE_DIRECTORY = File.join(File.dirname(__FILE__), 'command_templates')
  TEMPLATES = {
    import:     File.read(File.join(TEMPLATE_DIRECTORY, 'postgres_import.erb')),
    export:     File.read(File.join(TEMPLATE_DIRECTORY, 'postgres_export.erb')),
    gdb_export: File.read(File.join(TEMPLATE_DIRECTORY, 'postgres_gdb_export.erb'))
  }

  def self.import file_path, original_table_name=nil, table_name=nil
    raise ArgumentError, WRONG_ARGUMENTS_MSG if table_name && !original_table_name
    system ogr_command(TEMPLATES[:import], binding)
  end

  def self.export file_type, file_name, query, geom_type='polygon'
    template = file_type == :gdb ? TEMPLATES[:gdb_export] : TEMPLATES[:export]
    system ogr_command(template, binding)
  end

  private

  def self.db_config
    ActiveRecord::Base.connection_config
  end

  def self.ogr_command template, context
    compiled_template = ERB.new(template).result context
    compiled_template.squish
  end
end
