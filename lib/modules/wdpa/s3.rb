class Wdpa::S3
  def initialize
    @s3 = Aws::S3::Resource.new({
      access_key_id: Rails.application.secrets.aws_access_key_id,
      secret_access_key: Rails.application.secrets.aws_secret_access_key,
      region: Rails.application.secrets.s3_region
    })
  end

  def self.download_current_wdpa_to filename
    self.new.tap{ |s3| s3.download_current_wdpa_to filename }
  end

  def self.new_wdpa? since
    new.new_wdpa? since
  end

  def self.current_wdpa_identifier
    new.current_wdpa_identifier
  end

  def download_current_wdpa_to filename
    current_wdpa.get(response_target: filename, response_content_encoding: 'ASCII_8BIT')
  end

  def new_wdpa? since
    current_wdpa.last_modified > since
  end

  def current_wdpa_identifier
    # Assuming WDPA_WDOECM_MMMYYYY_Public.zip
    current_wdpa.key.split('_').third
  end

  private

  def current_wdpa
    available_wdpa_databases.sort_by(&:last_modified).last.object
  end

  def available_wdpa_databases
    bucket_name = Rails.application.secrets.aws_bucket
    @s3.bucket(bucket_name).objects
  end
end
