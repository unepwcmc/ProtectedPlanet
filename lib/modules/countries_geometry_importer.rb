class CountriesGeometryImporter
  def initialize
    @s3 = AWS::S3.new({
      access_key_id: Rails.application.secrets.aws_access_key_id,
      secret_access_key: Rails.application.secrets.aws_secret_access_key
    })
  end
  def self.download_current_wdpa_to filename: filename, filepath: filepath
    countries_geometries = self.new
    countries_geometries.download_countries_geometries_to filename: filename, filepath: filepath

    countries_geometries
  end

  def download_countries_geometries_to filename, filepath
    File.open(filepath, 'w:ASCII-8BIT') do |file|
      file.write countries_geometries(filename)
    end
  end

  def self.restore_table filepath
    system("pg_restore -c -i -U postgres -d pp_development -v #{filepath}")
  end

  def self.update_table type, country
    update_query(type,country)
  end

  def self.delete_temp_table
    delete_query
  end

  def self.delete_temp_file filepath
    File.delete filepath
  end

  private

  DB = ActiveRecord::Base.connection

  def countries_geometries filename
    bucket_name = Rails.application.secrets.aws_datasets_bucket
    @s3.buckets[bucket_name].objects[filename].read
  end


  def self.update_query type,country
      dirty_query = """
        UPDATE countries
        SET #{type.downcase}_geom = the_geom
        FROM countries_geometries_temp
        WHERE type = ? AND iso_3 = ?
    """.squish

    sql = ActiveRecord::Base.send(:sanitize_sql_array, [
      dirty_query, type, country
    ])
    DB.execute(sql)
  end

  def self.delete_query
    sql = "DELETE FROM countries_geometries_temp"
    DB.execute(sql)
  end




end