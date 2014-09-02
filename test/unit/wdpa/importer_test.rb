require 'test_helper'

class TestWdpaImporter < ActiveSupport::TestCase
  test '.import creates a WDPA Release, imports the protected areas from
   it, generates downloads for the imported PAs and cleans up' do
    wdpa_release = mock()
    wdpa_release.stubs(:clean_up)

    Wdpa::Release.expects(:download).returns(wdpa_release)
    Wdpa::SourceImporter.expects(:import).with(wdpa_release)
    Wdpa::ProtectedAreaImporter.expects(:import).with(wdpa_release)
    Wdpa::DownloadGenerator.expects(:generate)
    Wdpa::CountryGeometryPopulator.expects(:populate)
    Wdpa::CartoDbImporter.expects(:import).with(wdpa_release)

    Wdpa::Importer.import
  end
end
