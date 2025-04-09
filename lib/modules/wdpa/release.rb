class Wdpa::Release
  IMPORT_VIEW_NAME = "imported_protected_areas"
  DOWNLOADS_VIEW_NAME = "downloads_protected_areas"

  def self.download
    wdpa_release = self.new
    wdpa_release.download

    wdpa_release
  end

  def initialize
    @start_time = Time.now
  end

  def download
    Wdpa::S3.download_latest_wdpa_to zip_path
    system("unzip -j '#{zip_path}' '\*.gdb/\*' -d '#{gdb_path}'")
    Rails.logger.info("Downloaded latest WDPA files, now processing the raw data.")
    import_tables.each do |original_table, std_table|
      Ogr::Postgres.import(
        gdb_path,
        original_table,
        std_table
      )
    end

    create_import_view
    create_downloads_view
    Rails.logger.info("The raw data has been processed.")
  end

  def import_tables
    geometry_tables.merge(
      {source_table => Wdpa::DataStandard.standardise_table_name(source_table)}
    )
  end

  def geometry_tables
    @geometry_tables ||= begin
      gdb_metadata = Ogr::Info.new(gdb_path)
      geometry_tables = gdb_metadata.layers_matching(
        Wdpa::DataStandard::Matchers::GEOMETRY_TABLE
      )

      geometry_tables.each_with_object({}) do |tbl, hash|
        hash[tbl] = Wdpa::DataStandard.standardise_table_name(tbl)
      end
    end
  end

  def source_table
    gdb_metadata = Ogr::Info.new(gdb_path)
    @source_table ||= gdb_metadata.layers_matching(Wdpa::DataStandard::Matchers::SOURCE_TABLE).first
  end

  def create_import_view
    attributes = Wdpa::DataStandard.common_attributes.join(', ')
    create_query = "CREATE OR REPLACE VIEW #{IMPORT_VIEW_NAME} AS "

    select_queries = []
    select_queries << "SELECT #{attributes} FROM standard_polygons"
    select_queries << "SELECT #{attributes} FROM standard_points"

    create_query << select_queries.join(' UNION ALL ')

    db.execute(create_query)
  end

  def create_downloads_view
    create_query = "CREATE OR REPLACE VIEW #{DOWNLOADS_VIEW_NAME} AS "
    as_query = Download::Queries.mixed(true)

    db.execute(create_query + "(SELECT #{as_query[:select]} FROM #{as_query[:from]})")
  end

  def protected_areas
    geometry_tables.each_with_object([]) do |(_, std_table_name), protected_areas|
      protected_areas.concat(
        db.execute("SELECT * FROM #{std_table_name}").to_a
      )
    end
  end

  def protected_areas_in_bulk(size)
    geometry_tables.each_with_object([]) do |(_, std_table_name), protected_areas|
      total_pas = db.select_value("SELECT count(*) FROM #{std_table_name}").to_f
      pieces = (total_pas/size).ceil

      (0...pieces).each do |piece|
        query = "SELECT * FROM #{std_table_name} LIMIT #{size} OFFSET #{piece*size} ORDER BY wdpaid"
        Bystander.log(query)
        yield(db.execute(query).to_a)
      end
    end
  end

  def sources
    db.execute("SELECT * FROM #{Wdpa::DataStandard.standardise_table_name(source_table)}").to_a
  end

  def clean_up
    Rails.logger.info("We are now removing the files downloaded from S3")
    FileUtils.rm_rf(zip_path)
    FileUtils.rm_rf(gdb_path)
  end

  def zip_path
    "#{path_without_extension}.zip"
  end

  def gdb_path
    "#{path_without_extension}.gdb"
  end

  private

  def path_without_extension
    File.join(tmp_path, "wdpa-#{start_time}")
  end

  def tmp_path
    File.join(Rails.root, 'tmp')
  end

  def start_time
    @start_time.strftime("%Y-%m-%d-%H%M")
  end

  def db
    ActiveRecord::Base.connection
  end
end
