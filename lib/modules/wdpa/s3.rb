class Wdpa::S3
  def initialize
    @s3 = AWS::S3.new({
      access_key_id: Rails.application.secrets.aws_access_key_id,
      secret_access_key: Rails.application.secrets.aws_secret_access_key
    })
  end

  def self.download_current_wdpa_to filename: filename
    s3 = self.new
    s3.download_current_wdpa_to filename: filename

    s3
  end

  def download_current_wdpa_to filename: filename
    File.open(filename, 'w:ASCII-8BIT') do |file|
      file.write current_wdpa.read
    end
  end

  private

  def current_wdpa
    available_wdpa_databases.sort_by(&:last_modified).last
  end

  def available_wdpa_databases
    bucket_name = Rails.application.secrets.aws_bucket
    @s3.buckets[bucket_name].objects
  end
end
