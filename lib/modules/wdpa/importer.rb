class Wdpa::Importer
  def self.import
    importer = self.new
    importer.import
  end

  def import
    temp_db_name = "temp_import_db_#{Time.now.to_i}"

    ImportTools.with_db(temp_db_name) do
      wdpa_release = Wdpa::Release.download
      execute_importers wdpa_release
      wdpa_release.clean_up
    end
  end

  private

  def execute_importers wdpa_release
    Wdpa::SourceImporter.import wdpa_release
    Wdpa::ProtectedAreaImporter.import wdpa_release
    Wdpa::DownloadGenerator.generate
    Wdpa::CartoDbImporter.import wdpa_release
  end
end
