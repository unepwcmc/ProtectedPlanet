# frozen_string_literal: true

require 'test_helper'

class TestWdpaProtectedAreaImporter < ActiveSupport::TestCase
  test '#import imports the PA attributes and geometries' do
    # .import no longer takes the release as an argument
    Wdpa::ProtectedAreaImporter::AttributeImporter.expects(:import)
    Wdpa::ProtectedAreaImporter::GeometryImporter.expects(:import)
    Wdpa::Shared::Importer::ProtectedAreasRelatedSource.expects(:import_live)

    Wdpa::ProtectedAreaImporter.import
  end
end
