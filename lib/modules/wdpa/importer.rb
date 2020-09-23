class Wdpa::Importer
  def self.import
    importer = self.new
    importer.import
  end

  def import
    wdpa_release = Wdpa::Release.download
    execute_importers wdpa_release

    ImportWorkers::FinaliserWorker.can_be_started = true
    wdpa_release.clean_up
  end

  private

  def execute_importers wdpa_release
    Wdpa::SourceImporter.import wdpa_release
    Wdpa::ProtectedAreaImporter.import wdpa_release
    Wdpa::GeometryRatioCalculator.calculate
    Wdpa::NetworkImporter.import
    Wdpa::OverseasTerritoriesImporter.import
    Wdpa::GlobalStatsImporter.import
    Wdpa::GreenListImporter.import
    Wdpa::PameImporter.import
    Wdpa::StoryMapLinkListImporter.import
    Wdpa::BiopamaCountriesImporter.import
  end
end
