class Wdpa::Importer
  def self.import
    wdpa_release = Wdpa::Release.download

    Wdpa::SourceImporter.import wdpa_release
    Wdpa::ProtectedAreaImporter.import wdpa_release
    Wdpa::DownloadGenerator.generate
    Wdpa::CartoDbImporter.import wdpa_release

    wdpa_release.clean_up
  end
end
