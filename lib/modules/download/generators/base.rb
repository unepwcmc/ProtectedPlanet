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
    conn = ActiveRecord::Base.lease_connection
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
    run_zip("-j #{zip_path} #{path}") && add_sources && add_attachments
  end

  # `zip` exits 12 ("nothing to do") when every file named on the command line is
  # already in the archive, byte-identical -- which is exactly what a leftover
  # archive from an earlier attempt in tmp/ looks like. That is not a failure,
  # but `system` reports it as one: the download was then marked failed *and* the
  # stale archive was left in place, so every retry failed again for the same
  # reason and that identifier could never be downloaded again. Treat 12 as
  # success; let genuine zip errors through.
  ZIP_NOTHING_TO_DO = 12

  # Reads `system`'s own return value for the success path and only consults
  # `$?` for the exit code when it reports failure. Going straight to
  # `$?.success?` crashed with NoMethodError on nil whenever `system` had not
  # actually run in this thread -- `$?` is thread-local and starts out nil --
  # which is every caller whose `system` is stubbed. `&.` covers the same nil
  # on the failure path (and `system` returning nil for a command that could
  # not be executed at all).
  def run_zip(args, chdir: nil)
    opts = chdir ? { chdir: chdir } : {}
    return true if system("zip #{args}", **opts)

    exitstatus = $?&.exitstatus
    return true if exitstatus == ZIP_NOTHING_TO_DO

    Rails.logger.error("zip #{args} failed with status #{exitstatus.inspect}")
    false
  end

  def query(conditions = [])
    query = %(SELECT "TYPE", #{Download::Utils.download_columns})
    query << " FROM #{Download::Config.downloads_view}"
    add_conditions(query, conditions).squish
  end

  # See build_site_selection in app/workers/download_workers/base.rb for the usage
  def add_conditions(query, conditions)
    conditions = Array.wrap(conditions)

    add_selection_conditions(conditions) if @selection_entries.is_a?(Hash)

    query.tap do |q|
      q << " WHERE #{conditions.join(' AND ')}" if conditions.any?
    end
  end

  # Builds selection conditions for all download types.
  # Filter groups are AND-ed; site_ids and site_id_and_pid_pairs are OR-ed within one subgroup.
  def add_selection_conditions(conditions)
    # Empty hash means "no filters" and should download all records.
    return if @selection_entries.empty?

    site_ids          = (@selection_entries[:site_ids] || []).map(&:to_i).reject(&:zero?)
    site_id_pid_pairs = @selection_entries[:site_id_and_pid_pairs] || []
    is_oecm           = @selection_entries[:is_oecm]
    is_marine         = @selection_entries[:is_marine]
    iso3_vals         = Array(@selection_entries[:iso3]).reject(&:blank?)
    iucn_cats         = Array(@selection_entries[:iucn_categories]).reject(&:blank?)
    designations      = Array(@selection_entries[:designations]).reject(&:blank?)
    governance_types  = Array(@selection_entries[:governance_types]).reject(&:blank?)

    if site_ids.empty? && site_id_pid_pairs.empty? && iso3_vals.empty? &&
       is_oecm.nil? && is_marine.nil? &&
       iucn_cats.empty? && designations.empty? && governance_types.empty?
      conditions << '1=0'
      return
    end

    conditions << build_iso3_clause(iso3_vals)                    if iso3_vals.any?
    conditions << build_iucn_categories_clause(iucn_cats)         if iucn_cats.any?
    conditions << build_designations_clause(designations)         if designations.any?
    conditions << build_governance_types_clause(governance_types) if governance_types.any?
    conditions << build_marine_clause(is_marine)                  unless is_marine.nil?
    conditions << build_is_oecm_clause(is_oecm)                   unless is_oecm.nil?

    db_disjuncts = []
    db_disjuncts << build_site_ids_clause(site_ids)             if site_ids.any?
    db_disjuncts.concat(build_pair_clauses(site_id_pid_pairs))  if site_id_pid_pairs.any?
    conditions << "(#{db_disjuncts.join(' OR ')})"              if db_disjuncts.any?
  end

  def selection_entries_empty?
    return false if @selection_entries.nil?
    return true unless @selection_entries.is_a?(Hash)
    return true if @selection_entries[:has_filters_but_empty_matches]

    # Unified flat selection: an empty hash is valid and means "no filters" (download all).
    return false if @selection_entries.empty?

    site_ids = Array.wrap(@selection_entries[:site_ids])
    pairs = Array.wrap(@selection_entries[:site_id_and_pid_pairs])
    iso3s = Array.wrap(@selection_entries[:iso3])
    is_oecm = @selection_entries[:is_oecm]
    is_marine = @selection_entries[:is_marine]
    iucn_cats = Array.wrap(@selection_entries[:iucn_categories])
    designations = Array.wrap(@selection_entries[:designations])
    governance_types = Array.wrap(@selection_entries[:governance_types])
    site_ids.empty? && pairs.empty? && iso3s.empty? && is_oecm.nil? && is_marine.nil? &&
      iucn_cats.empty? && designations.empty? && governance_types.empty?
  end

  def build_marine_clause(marine_val)
    realm_vals = marine_val ? Download::Config.marine_realm_values : Download::Config.terrestrial_realm_values
    %("#{Download::Config.download_view_column_names[:realm]}" IN (#{sql_in_list(realm_vals)}))
  end

  def build_is_oecm_clause(is_oecm_val)
    site_type = is_oecm_val ? Download::Config.oecm_site_type_value : Download::Config.pa_site_type_value
    %("#{Download::Config.download_view_column_names[:site_type]}" IN (#{sql_in_list([site_type])}))
  end

  def build_iucn_categories_clause(iucn_cats)
    return nil if iucn_cats.blank?

    %("#{Download::Config.download_view_column_names[:iucn_cat]}" IN (#{sql_in_list(iucn_cats)}))
  end

  def build_designations_clause(designations)
    return nil if designations.blank?

    %("#{Download::Config.download_view_column_names[:desig_eng]}" IN (#{sql_in_list(designations)}))
  end

  def build_governance_types_clause(governance_types)
    return nil if governance_types.blank?

    %("#{Download::Config.download_view_column_names[:gov_type]}" IN (#{sql_in_list(governance_types)}))
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
    run_zip("-ru #{zip_path} #{File.basename(sources_path)}", chdir: File.dirname(sources_path))
  end

  def add_attachments
    run_zip("-ru #{zip_path} *", chdir: ATTACHMENTS_PATH)
  end

  def add_shapefile_readme
    run_zip("-j #{zip_path} #{SHAPEFILE_README_PATH}")
  end

  def path_without_extension
    filename_without_extension = File.basename(zip_path, File.extname(zip_path))
    File.join(File.dirname(zip_path), filename_without_extension)
  end

  def db
    ActiveRecord::Base.lease_connection
  end
end
