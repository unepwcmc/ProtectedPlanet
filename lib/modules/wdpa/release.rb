class Wdpa::Release
  WDPA_GEOMETRY_TABLE_MATCHER = /wdpa_?po/i
  WDPA_SOURCE_TABLE_MATCHER = /wdpa_?source/i

  def self.download
    wdpa_release = self.new
    wdpa_release.download

    wdpa_release
  end

  def initialize
    @start_time = Time.now
  end

  def download
    Wdpa::S3.download_current_wdpa_to filename: zip_path
    system("unzip -j '#{zip_path}' '\*.gdb/\*' -d '#{gdb_path}'")
    Ogr::Postgres.new.import file: gdb_path
  end

  def geometry_tables
    gdb_metadata = Ogr::Info.new(gdb_path)
    gdb_metadata.layers_matching(WDPA_GEOMETRY_TABLE_MATCHER)
  end

  def source_table
    gdb_metadata = Ogr::Info.new(gdb_path)
    gdb_metadata.layers_matching(WDPA_SOURCE_TABLE_MATCHER).first
  end

  def protected_areas
    connection = ActiveRecord::Base.connection

    attributes = geometry_tables.map do |table_name|
      connection.execute(
        "SELECT * FROM #{table_name}"
      ).to_a
    end

    attributes.flatten
  end

  def clean_up
    FileUtils.rm_rf(zip_path)
    FileUtils.rm_rf(gdb_path)

    geometry_tables.each do |table_name|
      ActiveRecord::Migration.drop_table(table_name)
    end
    ActiveRecord::Migration.drop_table(source_table)
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
end
