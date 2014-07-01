require 'digest/sha1'

class Download::Generator
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

  protected

  def export_from_postgres type
    with_view query do |view_name|
      Ogr::Postgres.export type, path, "SELECT * FROM #{view_name}"
    end
  end

  def with_view query
    query_shasum = Digest::SHA1.hexdigest query
    view_name = "tmp_downloads_#{query_shasum}"

    DB.execute "CREATE VIEW #{view_name} AS #{query}"
    yield view_name
  ensure
    DB.execute "DROP VIEW #{view_name}"
  end

  private

  DB = ActiveRecord::Base.connection

  def zip
    system("zip -j #{@zip_path} #{path}")
  end

  def query conditions = []
    conditions = Array.wrap(conditions)

    query = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME}"

    if @wdpa_ids.present?
      conditions << "wdpaid IN (#{@wdpa_ids.join(',')})"
    end

    if conditions.length > 0
      query << " WHERE #{conditions.join(' AND ')}"
    end

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
end
