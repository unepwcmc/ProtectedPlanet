require 'digest/sha1'

class Download::Generators::Base
  ATTACHMENTS_PATH = File.join(Rails.root, 'lib', 'data', 'documents', 'resources').freeze
  SHAPEFILE_README_PATH = File.join(Rails.root, 'lib', 'data', 'documents', 'Shapefile_splitting_README.txt').freeze
  TMP_DOWNLOADS_PREFIX = 'tmp_downloads_'
  SOURCE_CSV_PREFIX = 'WDPA_sources_'

  # For non-PDF generators, we accept a selection hash: nil (no filter),
  # { site_ids: [...] }, or { site_id_and_pid_pairs: [[site_id, site_pid], ...] }.
  def self.generate(zip_path, selection_entries = nil)
    generator = new zip_path, selection_entries
    generator.generate
  end

  def initialize(zip_path, selection_entries)
    @zip_path = zip_path
    @selection_entries = selection_entries
  end

  def generate
    return false if selection_entries_empty?

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

    Ogr::Postgres.export :csv, sources_path, "
      SELECT #{Download::Utils.source_columns}
      FROM #{Download::Config.sources_view}
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
    query << " FROM #{Download::Config.downloads_view}"
    add_conditions(query, conditions).squish
  end

  # See build_site_selection in app/workers/download_workers/general.rb for the usage
  def add_conditions(query, conditions)
    conditions = Array.wrap(conditions)

    if @selection_entries.is_a?(Hash)
      site_ids   = (@selection_entries[:site_ids] || []).map(&:to_i).reject(&:zero?)
      site_id_pid_pairs = build_pair_clauses(@selection_entries[:site_id_and_pid_pairs] || [])
      iso3_vals  = Array(@selection_entries[:iso3]).reject(&:blank?)
      site_types = Array(@selection_entries[:site_types]).reject(&:blank?)
      realms = Array(@selection_entries[:realms]).reject(&:blank?)

      if site_ids.empty? && site_id_pid_pairs.empty? && iso3_vals.empty? && site_types.empty? && realms.empty?
        conditions << "1=0"
      else
        disjuncts = []
        disjuncts << build_site_ids_clause(site_ids) if site_ids.any?
        disjuncts.concat(site_id_pid_pairs) if site_id_pid_pairs.any?
        disjuncts << build_iso3_clause(iso3_vals) if iso3_vals.any?
        disjuncts << build_site_types_clause(site_types) if site_types.any?
        disjuncts << build_realms_clause(realms) if realms.any?

        conditions << "(#{disjuncts.join(' OR ')})"
      end
    end

    query.tap do |q|
      q << " WHERE #{conditions.join(' AND ')}" if conditions.any?
    end
  end

  def selection_entries_empty?
    return false if @selection_entries.nil?
    return true unless @selection_entries.is_a?(Hash)

    site_ids = Array.wrap(@selection_entries[:site_ids])
    pairs = Array.wrap(@selection_entries[:site_id_and_pid_pairs])
    iso3s = Array.wrap(@selection_entries[:iso3])
    types = Array.wrap(@selection_entries[:site_types])
    realms = Array.wrap(@selection_entries[:realms])
    site_ids.empty? && pairs.empty? && iso3s.empty? && types.empty? && realms.empty?
  end

  def build_pair_clauses(pairs)
    pairs.each_with_object([]) do |(site_id, site_pid), clauses|
      next if site_id.to_i.zero? || site_pid.blank?

      escaped_pid = site_pid.to_s.gsub("'", "''")
      cols = Download::Config.download_view_column_names
      # Wrap in parentheses so each (site_id, site_pid) pair is treated as a unit when OR-ed
      clauses << %(("#{cols[:site_id]}" = #{site_id.to_i} AND "#{cols[:site_pid]}" = '#{escaped_pid}'))
    end
  end

  def build_site_ids_clause(site_ids)
    return nil if site_ids.blank?

    %("#{Download::Config.download_view_column_names[:site_id]}" IN (#{site_ids.join(',')}))
  end

  def build_iso3_clause(iso3_vals)
    return nil if iso3_vals.blank?

    iso3_list = sql_in_list(iso3_vals)
    %("#{Download::Config.download_view_column_names[:iso3]}" IN (#{iso3_list}))
  end

  def build_site_types_clause(site_types)
    return nil if site_types.blank?

    types_list = sql_in_list(site_types)
    %("#{Download::Config.download_view_column_names[:site_type]}" IN (#{types_list}))
  end

  def build_realms_clause(realms)
    return nil if realms.blank?

    realms_list = sql_in_list(realms)
    %("#{Download::Config.download_view_column_names[:realm]}" IN (#{realms_list}))
  end

  def sql_in_list(values)
    values.map { |v| "'#{v.to_s.gsub("'", "''")}'" }.join(',')
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
