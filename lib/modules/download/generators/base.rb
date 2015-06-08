require 'digest/sha1'

class Download::Generators::Base
  ATTACHMENTS_PATH = File.join(Rails.root, 'lib', 'data', 'documents')
  ATTACHMENTS = [
    File.join(ATTACHMENTS_PATH, 'Appendix\\ 5\\ _WDPA_Metadata.pdf'),
    File.join(ATTACHMENTS_PATH, 'Summary_table_WDPA_attributes.pdf'),
    File.join(ATTACHMENTS_PATH, 'WDPA_Manual_1.0.pdf')
  ]

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
    clean_up_after { export and zip }
  end

  private

  def export_from_postgres type
    view_name = create_view(query)
    Ogr::Postgres.export type, path, "SELECT * FROM #{view_name}"
  end

  def attachments_paths
    ATTACHMENTS.join(' ')
  end

  def create_view query
    query_shasum = Digest::SHA1.hexdigest query
    view_name = "tmp_downloads_#{query_shasum}"

    db.execute "CREATE OR REPLACE VIEW #{view_name} AS #{query}"
    return view_name
  end

  def export
    raise NotImplementedError
  end

  def zip
    system("zip -j #{@zip_path} #{path} #{attachments_paths}")
  end

  def query conditions=[]
    conditions = Array.wrap(conditions)
    conditions << "wdpaid IN (#{@wdpa_ids.join(',')})" if @wdpa_ids.present?

    query = "SELECT \"TYPE\", #{Download::Queries.for_polygons[:select]}"
    query << " FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}"
    query << " WHERE #{conditions.join(' AND ')}" if conditions.any?

    query
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

  def path_without_extension
    filename_without_extension = File.basename(@zip_path, File.extname(@zip_path))
    File.join(File.dirname(@zip_path), filename_without_extension)
  end

  def db
    ActiveRecord::Base.connection
  end
end
