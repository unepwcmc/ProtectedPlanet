class Download::Csv
  def self.generate zip_path, wdpa_ids = nil
    download_csv = new zip_path, wdpa_ids
    download_csv.generate
  end

  def initialize zip_path, wdpa_ids
    @zip_path = zip_path
    @wdpa_ids = wdpa_ids
  end

  def generate
    clean_up_after { export and zip }
  end

  private

  def export
    Ogr::Postgres.export :csv, csv_path, query
  end

  def zip
    system("zip -j #{@zip_path} #{csv_path}")
  end

  def query
    query = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME}"

    if @wdpa_ids.present?
       query << " WHERE wdpaid IN (#{@wdpa_ids.join(',')})"
    end

    query
  end

  def clean_up_after
    return_value = yield
    clean_up

    return_value
  end

  def clean_up
    FileUtils.rm_rf csv_path
  end

  def csv_path
    "#{path_without_extension}.csv"
  end

  def path_without_extension
    filename_without_extension = File.basename(@zip_path, File.extname(@zip_path))
    File.join(File.dirname(@zip_path), filename_without_extension)
  end
end
