require 'test_helper'

class TestWdpaProtectedAreaImporter < ActiveSupport::TestCase
  test "#import imports the PA attributes and geometries" do
    wdpa_release = Wdpa::Release.new

    Wdpa::ProtectedAreaImporter::AttributeImporter
      .expects(:import).with(wdpa_release)

    Wdpa::ProtectedAreaImporter::GeometryImporter
      .expects(:import).with(wdpa_release)

    Wdpa::ProtectedAreaImporter::AssetImporter.expects(:import)
    Wdpa::ProtectedAreaImporter::IrreplaceabilityImporter.expects(:import)

    Wdpa::ProtectedAreaImporter.import wdpa_release
  end
end
