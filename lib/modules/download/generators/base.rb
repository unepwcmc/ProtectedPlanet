require 'digest/sha1'

class Download::Generators::Base
  ATTACHMENTS_PATH = File.join(Rails.root, 'lib', 'data', 'documents', 'resources').freeze
  SHAPEFILE_README_PATH = File.join(Rails.root, 'lib', 'data', 'documents', 'Shapefile_splitting_README.txt').freeze
  TMP_DOWNLOADS_PREFIX = 'tmp_downloads_'

  def self.generate(zip_path, site_ids = nil)
    generator = new zip_path, site_ids
    generator.generate
  end

  def initialize(zip_path, site_ids)
    @zip_path = zip_path
    @site_ids = site_ids
  end

  def generate
    return false if @site_ids.is_a?(Array) && @site_ids.empty?

    clean_up_after { export and export_sources and zip }
  end

  # Drops all temporary download views created by generators
  # (views with names starting with "tmp_downloads_")
  def self.clean_tmp_download_views
    conn = ActiveRecord::Base.connection
    sql = <<-SQL
      SELECT table_name
      FROM information_schema.views
      WHERE table_schema = 'public'
        AND table_name LIKE '#{TMP_DOWNLOADS_PREFIX}%'
    SQL
    views = conn.select_values(sql)

    views.each do |view_name|
      conn.execute "DROP VIEW IF EXISTS #{view_name}"
    rescue StandardError => e
      Rails.logger.warn "Failed to drop temp download view #{view_name}: #{e.message}"
    end
    views.length
  end

  private

  def export_from_postgres(type)
    view_name = create_view(query)
    Ogr::Postgres.export type, path, "SELECT * FROM #{view_name}"
  end

  def create_view(query)
    query_shasum = Digest::SHA1.hexdigest query
    view_name = "#{TMP_DOWNLOADS_PREFIX}#{query_shasum}"

    db.execute "CREATE OR REPLACE VIEW #{view_name} AS #{query}"
    view_name
  end

  def export_sources
    return true if File.exist?(sources_path)

    Ogr::Postgres.export :csv, sources_path, "
      SELECT #{Download::Utils.source_columns}
      FROM #{Wdpa::Portal::Config::PortalImportConfig::PORTAL_MATERIALISED_VIEWS['sources']}
    "
  end

  def export
    raise NotImplementedError
  end

  def zip
    system("zip -j #{zip_path} #{path}")
    system("zip -ru #{zip_path} #{File.basename(sources_path)}", chdir: File.dirname(sources_path))
    system("zip -ru #{zip_path} *", chdir: ATTACHMENTS_PATH)
  end

  def query(conditions = [])
    query = %(SELECT "TYPE", #{Download::Utils.download_columns})
    query << " FROM #{Wdpa::Portal::Config::PortalImportConfig::PORTAL_VIEWS['downloads']}"
    add_conditions(query, conditions).squish
  end

  def add_conditions(query, conditions)
    conditions = Array.wrap(conditions)
    conditions << %{"SITE_ID" IN (#{@site_ids.join(',')})} if @site_ids.present?

    query.tap do |q|
      q << " WHERE #{conditions.join(' AND ')}" if conditions.any?
    end
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

  attr_reader :zip_path

  def sources_path
    File.join(File.dirname(zip_path), "WDPA_sources_#{Release.latest_succeeded_label}.csv")
  end

  def add_sources
    system("zip -ru #{zip_path} #{File.basename(sources_path)}", chdir: File.dirname(sources_path))
  end

  def add_attachments
    system("zip -ru #{zip_path} *", chdir: ATTACHMENTS_PATH)
  end

  def add_shapefile_readme
    system("zip -j #{zip_path} #{SHAPEFILE_README_PATH}")
  end

  def path_without_extension
    filename_without_extension = File.basename(zip_path, File.extname(zip_path))
    File.join(File.dirname(zip_path), filename_without_extension)
  end

  def db
    ActiveRecord::Base.connection
  end
end
