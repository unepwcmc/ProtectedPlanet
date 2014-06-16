require 'test_helper'

class TestSearch < ActiveSupport::TestCase
  test '#search runs a full text search and returns the matching PA models' do
    protected_area = FactoryGirl.create(:protected_area, wdpa_id: 1234)

    query = 'manbone'

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        SELECT wdpa_id
        FROM tsvector_search_documents
        WHERE document @@ to_tsquery('#{query}')
      """.squish).
      returns([{"wdpa_id" => protected_area.wdpa_id}])

    results = Search.search query
    found_protected_area = results.first

    assert_kind_of ProtectedArea, found_protected_area
    assert_equal   protected_area.id, found_protected_area.id
  end

  test '#search returns an empty array if no PAs are found' do
    query = 'manbone'

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        SELECT wdpa_id
        FROM tsvector_search_documents
        WHERE document @@ to_tsquery('#{query}')
      """.squish).
      returns([])

    results = Search.search query

    assert_equal 0, results.count
  end

  test '#search sanitizes potential SQL injections' do
    query = "' --"

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        SELECT wdpa_id
        FROM tsvector_search_documents
        WHERE document @@ to_tsquery(''' --')
      """.squish).
      returns([])

    Search.search query
  end
end
