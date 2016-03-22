require 'test_helper'

class TestWdpaAttributeImporterService < ActiveSupport::TestCase
  test '.import imports the WDPA Release protected areas as standardised
   Protected Areas' do
    pa_attributes = [{
      wdpaid: 1234,
      orig_name: 'Yosemite National Park'
    },{
      wdpaid: 4321,
      orig_name: 'Saratoga Creek Water District Park'
    }]

    wdpa_release = Wdpa::Release.new
    wdpa_release.expects(:protected_areas_in_bulk).yields(pa_attributes)

    imported = Wdpa::ProtectedAreaImporter::AttributeImporter.import(wdpa_release)

    assert imported, "Expected importer to return true on success"
    assert_equal 2, ProtectedArea.count

    assert_not_nil ProtectedArea.where(wdpa_id: 1234).first
    assert_not_nil ProtectedArea.where(wdpa_id: 4321).first
  end

  test '.import works with stringified keys' do
    pa_attributes = [{
      "wdpaid" => 1234,
      "orig_name" => 'Yosemite National Park'
    },{
      "wdpaid" => 4321,
      "orig_name" => 'Saratoga Creek Water District Park'
    }]

    wdpa_release = Wdpa::Release.new
    wdpa_release.expects(:protected_areas_in_bulk).yields(pa_attributes)

    imported = Wdpa::ProtectedAreaImporter::AttributeImporter.import(wdpa_release)

    assert imported, "Expected importer to return true on success"
    assert_equal 2, ProtectedArea.count

    assert_not_nil ProtectedArea.where(wdpa_id: 1234).first
    assert_not_nil ProtectedArea.where(wdpa_id: 4321).first
  end

  test '.import ignores geometry attributes and attributes that are not
   in the standard' do
    pa_attributes = [{
      wdpaid: 123,
      wkb_geometry: "don't tread on me"
    }]

    Wdpa::DataStandard.
      expects(:attributes_from_standards_hash).
      with({wdpaid: 123}).
      returns({wdpa_id: 123})

    wdpa_release = Wdpa::Release.new
    wdpa_release.expects(:protected_areas_in_bulk).yields(pa_attributes)

    imported = Wdpa::ProtectedAreaImporter::AttributeImporter.import(wdpa_release)

    assert imported, "Expected importer to return true on success"
    assert_equal 1, ProtectedArea.count
  end

end
