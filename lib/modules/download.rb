class Download
  TMP_PATH = File.join(Rails.root, 'tmp')
  CURRENT_PREFIX = 'current/'
  IMPORT_PREFIX = 'import/'

  GENERATORS = [
    Download::Csv,
    Download::Shapefile,
    Download::Kml
  ]

  def self.generate download_name, opts={}
    download = Download.new download_name, opts
    download.generate
  end

  def self.link_to object_name, type
    download = Download.new object_name
    download.link_to type
  end

  def self.make_current
    S3.replace_all IMPORT_PREFIX, CURRENT_PREFIX
  end

  def initialize download_name, opts={}
    @download_name = download_name
    @wdpa_ids = opts[:wdpa_ids]
    @for_import = opts[:for_import]
  end

  def link_to type
    file_name = File.basename zip_path_for_type(type)
    prefixed_file_name = CURRENT_PREFIX + file_name

    bucket_name = Rails.application.secrets.aws_downloads_bucket
    url = "https://#{bucket_name}.s3.amazonaws.com"

    URI.join(url, prefixed_file_name).to_s
  end

  def generate
    GENERATORS.each do |generator|
      type = generator.to_s.demodulize.downcase
      zip_path = zip_path_for_type(type)

      generated = generator.generate zip_path, @wdpa_ids

      if generated
        upload_to_s3 zip_path
        clean_up zip_path
      end
    end
  end

  private

  def upload_to_s3 zip_path
    download_name = File.basename(zip_path)
    prefix = @for_import ? IMPORT_PREFIX : CURRENT_PREFIX
    prefixed_download_name = prefix + download_name

    S3.upload prefixed_download_name, zip_path
  end

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
