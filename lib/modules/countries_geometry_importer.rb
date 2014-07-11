class CountriesGeometryImporter
  def initialize filename, filepath
    @s3 = AWS::S3.new({
      access_key_id: Rails.application.secrets.aws_access_key_id,
      secret_access_key: Rails.application.secrets.aws_secret_access_key
    })
    @filename = filename
    @filepath = filepath
  end


  def download_countries_geometries
    File.open(@filepath, 'w:ASCII-8BIT') do |file|
      file.write countries_geometries
    end
  end

  def restore_table 
    system("pg_restore -c -i -U postgres -d pp_development -v #{@filepath}")
  end

  def update_table type, country
    update_query(type,country)
  end

  def delete_temp_table
    delete_query
  end

  def delete_temp_file
    File.delete @filepath
  end

  private

  DB = ActiveRecord::Base.connection

  def countries_geometries 
    bucket_name = Rails.application.secrets.aws_datasets_bucket
    @s3.buckets[bucket_name].objects[@filename].read
  end


  def update_query type,country
      dirty_query = """
        UPDATE countries
        SET #{type.downcase}_geom = the_geom
        FROM (SELECT ST_Collectionextract(ST_collect(the_geom),3) the_geom
                FROM countries_geometries_temp
                WHERE type = ? AND iso_3 = ?) a
        WHERE iso_3 = ?
    """.squish

    sql = ActiveRecord::Base.send(:sanitize_sql_array, [
      dirty_query, type, country, country
    ])
    DB.execute(sql)
  end

  def delete_query
    sql = "DELETE FROM countries_geometries_temp"
    DB.execute(sql)
  end




end