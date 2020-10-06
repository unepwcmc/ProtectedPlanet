require 'digest/sha1'

class Download::Generators::Base
  ATTACHMENTS_PATH = File.join(Rails.root, 'lib', 'data', 'documents', 'resources').freeze
  SHAPEFILE_README_PATH = File.join(Rails.root, 'lib', 'data', 'documents', 'Shapefile_splitting_README.txt').freeze

  def self.generate zip_path, wdpa_ids = nil
    generator = new zip_path, wdpa_ids
    generator.generate
  end

  def initialize zip_path, wdpa_ids
    @zip_path = zip_path
    @wdpa_ids = wdpa_ids
  end

  def generate
    return false if @wdpa_ids.is_a?(Array) && @wdpa_ids.empty?
    clean_up_after { export and export_sources and zip }
  end

  private

  def export_from_postgres type
    view_name = create_view(query)
    Ogr::Postgres.export type, path, "SELECT * FROM #{view_name}"
  end

  def create_view query
    query_shasum = Digest::SHA1.hexdigest query
    view_name = "tmp_downloads_#{query_shasum}"

    db.execute "CREATE OR REPLACE VIEW #{view_name} AS #{query}"
    return view_name
  end

  def export_sources
    return true if File.exists?(sources_path)

    Ogr::Postgres.export :csv, sources_path, """
      SELECT #{Download::Utils.source_columns}
      FROM standard_sources
    """
  end

  def export
    raise NotImplementedError
  end

  def zip
    system("zip -j #{zip_path} #{path}")
    system("zip -ru #{zip_path} #{File.basename(sources_path)}", chdir: File.dirname(sources_path))
    system("zip -ru #{zip_path} *", chdir: ATTACHMENTS_PATH)
  end

  def query conditions=[]
    query = %{SELECT "TYPE", #{Download::Utils.download_columns}}
    query << " FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}"
    add_conditions(query, conditions).squish
  end

  def add_conditions query, conditions
    conditions = Array.wrap(conditions)
    conditions << %{"WDPAID" IN (#{@wdpa_ids.join(',')})} if @wdpa_ids.present?

    query.tap { |q|
      q << " WHERE #{conditions.join(' AND ')}" if conditions.any?
    }
  end

  def clean_up_after
    return_value = yield
    clean_up

    return_value
  end

  def clean_up
    FileUtils.rm_rf path
  end

  def path
    raise NotImplementedError
  end

  def zip_path
    @zip_path
  end

  def sources_path
    File.join(File.dirname(zip_path), "WDPA_sources.csv")
  end

  def add_sources
    system("zip -ru #{zip_path} #{File.basename(sources_path)}", chdir: File.dirname(sources_path))
  end

  def add_attachments
    system("zip -ru #{zip_path} *", chdir: ATTACHMENTS_PATH)
  end

  def add_shapefile_readme
    system("zip -ru #{zip_path} #{SHAPEFILE_README_PATH}")
  end

  def path_without_extension
    filename_without_extension = File.basename(zip_path, File.extname(zip_path))
    File.join(File.dirname(zip_path), filename_without_extension)
  end

  def db
    ActiveRecord::Base.connection
  end
end
