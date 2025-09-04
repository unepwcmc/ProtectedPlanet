class Wdpa::Importer
  def self.import
    importer = new
    importer.import
  end

  def import
    wdpa_release = Wdpa::Release.download
    execute_importers wdpa_release

    ImportWorkers::FinaliserWorker.can_be_started = true
    wdpa_release.clean_up
  end

  private

  def execute_importers(wdpa_release)
    Rails.logger.info('Wdpa::Importer.execute_importers: We are now running several importers to copy data from the raw data and CSVs into db')
    Wdpa::SourceImporter.import wdpa_release
    Wdpa::ProtectedAreaImporter.import
    Wdpa::GeometryRatioCalculator.calculate
    Wdpa::NetworkImporter.import # As of 20Aug2025, this is no longer used see lib/modules/wdpa/network_importer.rb
    Wdpa::Shared::Importer::CountryOverseasTerritories.import
    Wdpa::Shared::Importer::GlobalStats.import_live
    Wdpa::GreenListImporter.import
    Wdpa::PameImporter.import
    Wdpa::Shared::Importer::StoryMapLinkList.import_live
    Wdpa::BiopamaCountriesImporter.import
    Rails.logger.info('Wdpa::Importer.execute_importers: All importers have completed its job')
  end
end
