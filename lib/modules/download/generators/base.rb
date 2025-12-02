require 'digest/sha1'

class Download::Generators::Base
  ATTACHMENTS_PATH = File.join(Rails.root, 'lib', 'data', 'documents', 'resources').freeze
  SHAPEFILE_README_PATH = File.join(Rails.root, 'lib', 'data', 'documents', 'Shapefile_splitting_README.txt').freeze
  TMP_DOWNLOADS_PREFIX = 'tmp_downloads_'
  SOURCE_CSV_PREFIX = 'WDPA_sources_'

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

  # Cleans up all WDPA_sources_*.csv files in the tmp directory
  # regardless of which release label/month they belong to
  # Can be called as a class method for manual cleanup
  def self.clean_up_generated_source
    tmp_dir = Download::TMP_PATH
    pattern = File.join(tmp_dir, "#{SOURCE_CSV_PREFIX}*.csv")
    
    deleted_count = 0
    Dir.glob(pattern).each do |csv_file|
      FileUtils.rm_f(csv_file)
      Rails.logger.info "Cleaned up source CSV: #{csv_file}"
      deleted_count += 1
    end
    deleted_count
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
  
    sql = "SELECT #{Download::Utils.source_columns} FROM #{Download::Config.sources_view}"
    escaped_sql = sql.gsub('"', '\"')
  
    Ogr::Postgres.export(:csv, sources_path, escaped_sql)
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
    query << " FROM #{Download::Config.downloads_view}"
    add_conditions(query, conditions).squish
  end

  def add_conditions(query, conditions)
    conditions = Array.wrap(conditions)
    if @site_ids.present?
      sanitized_ids = @site_ids.select { |id| id.to_s =~ /\A\d+\z/ }.map(&:to_i)
      if sanitized_ids.empty?
        # If site_ids were provided but none are valid, ensure no rows are returned
        conditions << "1=0"
      else
        # Use SITE_ID for portal views, WDPAID for standard views
        conditions << %{"#{Download::Config.id_column}" IN (#{sanitized_ids.join(',')})}
      end
    end
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
    File.join(File.dirname(zip_path), "#{SOURCE_CSV_PREFIX}#{Download::Config.current_label}.csv")
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
