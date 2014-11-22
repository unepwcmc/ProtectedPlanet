module Download
  module Utils
    def self.link_to download_name, type
      file_name = File.basename zip_path_for_type(download_name, type)
      prefixed_file_name = CURRENT_PREFIX + file_name

      bucket_name = Rails.application.secrets.aws_downloads_bucket
      url = "https://#{bucket_name}.s3.amazonaws.com"

      URI.join(url, prefixed_file_name).to_s
    end

    def self.make_current
      S3.replace_all IMPORT_PREFIX, CURRENT_PREFIX
    end

    def self.zip_path_for_type download_name, type
      path = File.join(TMP_PATH, filename_for_type(download_name, type))
      "#{path}.zip"
    end

    def self.filename_for_type download_name, type
      "#{download_name}-#{type}"
    end
  end
end
