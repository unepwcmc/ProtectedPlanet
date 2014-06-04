class Ogr::Postgres
  DB_CONFIG = Rails.configuration.database_configuration[Rails.env]

  def import file: , to: DB_CONFIG["database"]
    @file_path = file
    @database_name = to

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
