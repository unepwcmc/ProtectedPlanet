require 'test_helper'

class TestWdpaImporter < ActiveSupport::TestCase
  test '.import creates a WDPA Release, imports the protected areas from
   it, generates downloads for the imported PAs, enables the FinaliserWorker
   and cleans up' do
    import = sequence('import')

    wdpa_release = mock()
    wdpa_release.stubs(:clean_up)

    Wdpa::Release.expects(:download).returns(wdpa_release).in_sequence(import)
    Wdpa::SourceImporter.expects(:import).with(wdpa_release).in_sequence(import)
    Wdpa::ProtectedAreaImporter.expects(:import).with(wdpa_release).in_sequence(import)
    Wdpa::NetworkImporter.expects(:import).in_sequence(import)
    Wdpa::OverseasTerritoriesImporter.expects(:import).in_sequence(import)
    Wdpa::GlobalStatsImporter.expects(:import).in_sequence(import)
    Wdpa::GreenListImporter.expects(:import).in_sequence(import)

    ImportWorkers::FinaliserWorker.expects(:can_be_started=).with(true).in_sequence(import)

    Wdpa::Importer.import
  end
end
