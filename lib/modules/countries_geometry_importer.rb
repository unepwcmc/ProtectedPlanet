class CountriesGeometryImporter
  FILEPATH = Rails.root.join('tmp', 'countries_geometries_dump.tar.gz').to_s

  RESTORE_TEMPLATE = File.read(File.join(File.dirname(__FILE__), 'pg_restore_command.erb'))

  AREA_TYPES = ['LAND','TS','EEZ']
  COMPLEX_COUNTRIES = { 'TS' => ['CIV'],'LAND' => [],'EEZ' => []}

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
    download
    restore_to_temporary_table
    copy_countries
  ensure
    cleanup
  end

  private

  def db
    ActiveRecord::Base.connection
  end

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
    db_config = ActiveRecord::Base.connection_config
    system restore_command(binding)
  end

  def restore_command context
    compiled_template = ERB.new(RESTORE_TEMPLATE).result context
    compiled_template.squish
  end

  def update_query type, iso_3
    """
      UPDATE countries
      SET #{type.downcase}_geom = the_geom
      FROM (
        SELECT ST_Makevalid(ST_CollectionExtract(ST_Collect(the_geom),3)) the_geom
        FROM countries_geometries_temp
        WHERE type = '#{type}' AND iso_3 = '#{iso_3}'
      ) a
      WHERE iso_3 = '#{iso_3}'
    """.squish
  end

  def simplify_query type, iso_3
    """UPDATE countries 
       SET #{type.downcase}_geom = st_simplify(#{type.downcase}_geom, 0.01) 
       WHERE iso_3 = '#{iso_3}'"""
  end

  def copy_countries
    countries = Country.pluck(:iso_3)

    countries.each do |iso_3|
      AREA_TYPES.each do |type|
        db.execute update_query(type, iso_3)
        if COMPLEX_COUNTRIES[type].include? iso_3
          db.execute simplify_query(type, iso_3)
        end
      end
    end
  end

  def cleanup
    db.execute("DELETE FROM countries_geometries_temp")
    File.delete(FILEPATH)
  end
end
