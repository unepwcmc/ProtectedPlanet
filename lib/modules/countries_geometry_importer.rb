class CountriesGeometryImporter
  FILEPATH = Rails.root.join('tmp', 'countries_geometries_dump.tar.gz').to_s
  AREA_TYPES = ['LAND','TS','EEZ']

  def self.import
    importer = self.new
    importer.import
  end

  def initialize
    @s3 = AWS::S3.new({
      access_key_id: Rails.application.secrets.aws_access_key_id,
      secret_access_key: Rails.application.secrets.aws_secret_access_key
    })
  end

  def import
    download and restore_to_temporary_table and copy_countries and cleanup
  end

  private

  DB = ActiveRecord::Base.connection

  def download
    File.open(FILEPATH, 'w:ASCII-8BIT') do |file|
      file.write compressed_geometries
    end
  end

  def compressed_geometries
    bucket_name = Rails.application.secrets.aws_datasets_bucket
    filename = File.basename(FILEPATH)

    @s3.buckets[bucket_name].objects[filename].read
  end

  def restore_to_temporary_table
    db_name = ActiveRecord::Base.connection.current_database
    system("pg_restore -c -i -U postgres -d #{db_name} -v #{FILEPATH}")
  end

  def update_query type, iso_3
    """
      UPDATE countries
      SET #{type.downcase}_geom = the_geom
      FROM (
        SELECT ST_CollectionExtract(ST_Collect(the_geom),3) the_geom
        FROM countries_geometries_temp
        WHERE type = '#{type}' AND iso_3 = '#{iso_3}'
      ) a
      WHERE iso_3 = '#{iso_3}'
    """.squish
  end

  def copy_countries
    countries = Country.pluck(:iso_3)

    countries.each do |iso_3|
      AREA_TYPES.each do |type|
        puts "Updating for #{type} #{iso_3}"
        query = update_query(type, iso_3)
        puts query
        DB.execute query
      end
    end
  end

  def cleanup
    DB.execute("DELETE FROM countries_geometries_temp")
    File.delete(FILEPATH)
  end
end
