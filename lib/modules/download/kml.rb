class Download::Kml
  QUERY = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME}"

  def self.generate zip_path
    download_kml = new zip_path
    download_kml.generate

    download_kml
  end

  def initialize zip_path
    @zip_path = zip_path
  end

  def generate
    export_success = Ogr::Postgres.export :kml, kml_path, QUERY
    if export_success
      return system("zip -j #{@zip_path} #{kml_path}")
    end
  end

  private

  def kml_path
    "#{path_without_extension}.kml"
  end

  def path_without_extension
    filename_without_extension = File.basename(@zip_path, File.extname(@zip_path))
    File.join(File.dirname(@zip_path), filename_without_extension)
  end
end
