class Wdpa::Importer
  def self.import
    wdpa_release = Wdpa::Release.download

    Wdpa::ProtectedAreaImporter.import wdpa_release
    Wdpa::DownloadGenerator.generate

    wdpa_release.clean_up
  end
end
