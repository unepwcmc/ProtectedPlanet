class Download
  TMP_PATH = File.join(Rails.root, 'tmp')

  GENERATORS = [
    Download::Csv,
    Download::Shapefile,
    Download::Kml
  ]

  def self.generate country_ids=nil
    download = Download.new country_ids
    download.generate
  end

  def initialize country_ids
    @download_type = country_ids || 'all'
  end

  def generate
    GENERATORS.each do |generator|
      type = generator.to_s.demodulize.downcase
      zip_path = zip_path_for_type(type)

      generator.generate zip_path
      Download::S3.upload zip_path
    end
  end

  private

  def zip_path_for_type type
    path = File.join(TMP_PATH,filename_for_type(type))
    "#{path}.zip"
  end

  def filename_for_type type
    "#{@download_type}-#{type}"
  end
end
