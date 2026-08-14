require 'test_helper'

# Characterization for the story-map-link importer (was ~10%). Reads a site_id/link/type CSV
# and creates StoryMapLink rows for matching protected areas. CSV stubbed; records real.
class Wdpa::Shared::Importer::StoryMapLinkListTest < ActiveSupport::TestCase
  Importer = Wdpa::Shared::Importer::StoryMapLinkList

  def stub_csv(rows)
    CSV.stubs(:read).returns([%w[site_id link type]] + rows)
  end

  test 'creates a story map link for a matching protected area' do
    pa = FactoryBot.create(:protected_area, site_id: 123)
    stub_csv([['123', 'http://example.com/story', 'esri']])

    result = Importer.import_data(ProtectedArea, StoryMapLink)
    assert_equal 1, result[:links_processed]
    assert_equal 1, result[:links_created]
    link = StoryMapLink.find_by(protected_area: pa)
    assert_equal 'http://example.com/story', link.link
    assert_equal 'esri', link.link_type
  end

  test 'counts sites that do not exist' do
    stub_csv([['999', 'http://example.com/story', 'esri']])
    result = Importer.import_data(ProtectedArea, StoryMapLink)
    assert_equal 1, result[:sites_not_found]
    assert_equal 0, result[:links_created]
    assert_includes result[:sites_not_found_list], '999'
  end

  test 'flags an invalid site_id and does not create a link' do
    stub_csv([['not-a-number', 'http://example.com/story', 'esri']])
    result = Importer.import_data(ProtectedArea, StoryMapLink)
    assert_equal 0, result[:links_created]
    assert(result[:soft_errors].any? { |e| e.include?('Invalid site_id') })
  end
end
