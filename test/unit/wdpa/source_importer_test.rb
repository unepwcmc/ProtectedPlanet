require 'test_helper'

class TestSourceImporter < ActiveSupport::TestCase
  test '.import imports the source in the given WDPA Release and assigns
   the match protected areas' do
    source_attributes = [{
      metadataid: 5984
    }, {
      metadataid: 4873
    }, {
      metadataid: 1432
    }]

    wdpa_release = Wdpa::Release.new
    wdpa_release.expects(:sources).returns(source_attributes)

    imported = Wdpa::SourceImporter.import wdpa_release

    assert imported, "Expected importer to return true on success"
    assert_equal 3, Source.count

    assert_same_elements [5984, 4873, 1432], Source.pluck(:metadataid)
  end
end
