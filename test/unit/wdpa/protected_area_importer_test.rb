# frozen_string_literal: true

require 'test_helper'

class TestWdpaProtectedAreaImporter < ActiveSupport::TestCase
  test '#import imports the PA attributes and geometries' do
    wdpa_release = Wdpa::Release.new

    Wdpa::ProtectedAreaImporter::AttributeImporter.expects(:import)
    Wdpa::ProtectedAreaImporter::GeometryImporter.expects(:import)
    Wdpa::ProtectedAreaImporter::RelatedSourceImporter.expects(:import).twice

    Wdpa::ProtectedAreaImporter.import wdpa_release
  end
end
