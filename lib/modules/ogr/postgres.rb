class Ogr::Postgres
  WRONG_ARGUMENTS_MSG = 'Given new table name, but no original table name'
  DB_CONFIG = Rails.configuration.database_configuration[Rails.env]

  def self.import file_path, original_table_name=nil, table_name=nil
    if table_name && !original_table_name
      raise ArgumentError, WRONG_ARGUMENTS_MSG
    end

    ogr = self.new
    ogr.import file_path, original_table_name, table_name

    ogr
  end

  def import file_path, original_table_name=nil, table_name=nil
    @file_path = file_path
    @original_table_name = original_table_name
    @table_name = table_name

    system(ogr_command)
  end

  private

  def ogr_command
    ogr_command_template.squish
  end

  def ogr_command_template
    template_path = File.join(File.dirname(__FILE__), 'ogr_postgres_command.erb')
    template = File.read(template_path)

    ERB.new(template).result binding
  end
end
