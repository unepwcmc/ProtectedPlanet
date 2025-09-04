require 'test_helper'

class Wdpa::Portal::ImporterTest < ActiveSupport::TestCase
  test '.import creates a Portal Release and imports using portal importers' do
    import = sequence('portal_import')

    portal_release = mock
    portal_release.stubs(:create_import_view)

    Wdpa::Portal::Importers::SourceImporter.expects(:import).with('sources_staging').in_sequence(import)
    Wdpa::Portal::Importers::ProtectedAreaAttribute.expects(:import).with('protected_areas_new').in_sequence(import)
    Wdpa::Portal::Importers::ProtectedAreaGeometry.expects(:import).with('protected_areas_new').in_sequence(import)
    Wdpa::Shared::Importer::ProtectedAreasRelatedSource.expects(:import_staging).twice.in_sequence(import)

    ImportWorkers::FinaliserWorker.expects(:can_be_started=).with(true).in_sequence(import)

    Wdpa::Portal::Importer.import
  end
end
