class Download
  TMP_PATH = File.join(Rails.root, 'tmp')

  GENERATORS = [
    Download::Csv,
    Download::Shapefile,
    Download::Kml
  ]

  def self.generate download_name, pa_ids=nil
    download = Download.new download_name, pa_ids
    download.generate
  end

  def initialize download_name, pa_ids=nil
    @download_name = download_name
    @pa_ids = pa_ids
  end

  def generate
    GENERATORS.each do |generator|
      type = generator.to_s.demodulize.downcase
      zip_path = zip_path_for_type(type)
      download_name = File.basename(zip_path)

      generator.generate zip_path
      S3.upload download_name, zip_path
    end
  end

  private

  def zip_path_for_type type
    path = File.join(TMP_PATH,filename_for_type(type))
    "#{path}.zip"
  end

  def filename_for_type type
    "#{@download_name}-#{type}"
  end
end
