class Download::Csv
  QUERY = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME}"

  def self.generate zip_path
    download_csv = new zip_path
    download_csv.generate

    download_csv
  end

  def initialize zip_path
    @zip_path = zip_path
  end

  def generate
    export_success = Ogr::Postgres.export :csv, csv_path, QUERY
    if export_success
      return system("zip -j #{@zip_path} #{csv_path}")
    end
  end

  private

  def csv_path
    "#{path_without_extension}.csv"
  end

  def path_without_extension
    filename_without_extension = File.basename(@zip_path, File.extname(@zip_path))
    File.join(File.dirname(@zip_path), filename_without_extension)
  end
end
