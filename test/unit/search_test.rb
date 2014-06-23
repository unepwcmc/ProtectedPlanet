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
        WHERE document @@ to_tsquery(''' & --')
      """.squish).
      returns([])

    Search.search query
  end

  test '#search squishes the query and joins the lexemes with & (and) operators' do
    query = ' Killbear and   the Manbone'

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        SELECT wdpa_id
        FROM tsvector_search_documents
        WHERE document @@ to_tsquery('Killbear & and & the & Manbone')
      """.squish).
      returns([])

    Search.search query
  end

  test '#search, given a page and limit, constructs a search query
   using offset and limit to paginate the results' do
    query = 'manbone'

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        SELECT wdpa_id
        FROM tsvector_search_documents
        WHERE document @@ to_tsquery('manbone')
        LIMIT 20
        OFFSET 20
      """.squish).
      returns([])

    Search.search query, page: 2, limit: 20
  end

  test '#search, given a string page and limit value, correctly
   paginates' do
    query = 'manbone'

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        SELECT wdpa_id
        FROM tsvector_search_documents
        WHERE document @@ to_tsquery('manbone')
        LIMIT 20
        OFFSET 20
      """.squish).
      returns([])

    Search.search query, page: "2", limit: "20"
  end

  test '#count, given a query, returns the number of results that would
   be returned' do
    query = 'manbone'

    ActiveRecord::Base.connection.
      expects(:execute).
      with("""
        SELECT COUNT(wdpa_id)
        FROM tsvector_search_documents
        WHERE document @@ to_tsquery('manbone')
      """.squish).
      returns([{"count"=> 1}])

    results_count = Search.count(query)

    assert_equal 1, results_count
    assert_kind_of Integer, results_count
  end
end
