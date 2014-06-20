class Download
  TMP_PATH = File.join(Rails.root, 'tmp')

  GENERATORS = [
    Download::Csv,
    Download::Shapefile,
    Download::Kml
  ]

  def self.generate download_name, wdpa_ids=nil
    download = Download.new download_name, wdpa_ids
    download.generate
  end

  def self.link_to object_name, type
    download = Download.new object_name
    download.link_to type
  end

  def initialize download_name, wdpa_ids=nil
    @download_name = download_name
    @wdpa_ids = wdpa_ids
  end

  def link_to type
    file_name = File.basename zip_path_for_type(type)

    bucket_name = Rails.application.secrets.aws_downloads_bucket
    url = "https://#{bucket_name}.s3.amazonaws.com"

    URI.join(url, file_name).to_s
  end

  def generate
    GENERATORS.each do |generator|
      type = generator.to_s.demodulize.downcase
      zip_path = zip_path_for_type(type)
      download_name = File.basename(zip_path)

      generator.generate zip_path, @wdpa_ids
      S3.upload download_name, zip_path

      clean_up zip_path
    end
  end

  private

  def clean_up path
    FileUtils.rm_rf path
  end

  def zip_path_for_type type
    path = File.join(TMP_PATH,filename_for_type(type))
    "#{path}.zip"
  end

  def filename_for_type type
    "#{@download_name}-#{type}"
  end
end
