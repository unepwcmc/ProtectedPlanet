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

  private



  def countries_geometries filename
    bucket_name = Rails.application.secrets.aws_datasets_bucket
    @s3.buckets[bucket_name].objects[filename].read
  end
end