class Wdpa::Importer
  def self.import
    wdpa_release = Wdpa::Release.download

    Wdpa::ProtectedAreaImporter.import wdpa_release

    wdpa_release.clean_up
  end
end
