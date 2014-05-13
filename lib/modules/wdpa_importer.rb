class WdpaImporter
  def import_table table_name
  end

  private

  def import_table table_name
    protected_areas_to_import(table_name).each do |protected_area|
      # create 
    end
  end

  def protected_areas_to_import table_name
    db[table_name.to_sym].use_cursor
  end

  def db_config
    Rails.configuration.database_configuration[Rails.env].symbolize_keys!
  end

  def db
    pg_credentials = "#{db_config[:username]}"
    if db_config[:password].present?
      pg_credentials += ":#{db_config[:password]}"
    end

    pg_url = "postgres://#{pg_credentials}@#{db_config[:host]}/pp_import"

    return Sequel.connect(pg_url) 
  end
end
