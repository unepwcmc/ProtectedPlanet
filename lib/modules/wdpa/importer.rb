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
    Rails.logger.info("We are now running several importers to copy data from the raw data and CSVs into db")
    Wdpa::SourceImporter.import wdpa_release
    Wdpa::ProtectedAreaImporter.import
    Wdpa::GeometryRatioCalculator.calculate
    Wdpa::NetworkImporter.import
    Wdpa::OverseasTerritoriesImporter.import
    Wdpa::GlobalStatsImporter.import
    Wdpa::GreenListImporter.import
    Wdpa::PameImporter.import
    Wdpa::StoryMapLinkListImporter.import
    Wdpa::BiopamaCountriesImporter.import
    Rails.logger.info("All importers have completed its job")
  end
end
