require 'test_helper'

class TestSearch < ActiveSupport::TestCase
  test '#search runs a full text search and returns the matching PA models' do
    search_query = 'manbone'

    query = """
      SELECT wdpa_id, ts_rank(document, query) AS rank
      FROM tsvector_search_documents, to_tsquery('#{search_query}:*') query
      WHERE document @@ query
    """.squish

    order_mock = mock()
    order_mock.expects(:order).with("rank DESC").returns([])

    ProtectedArea.expects(:joins).with("""
      INNER JOIN (
        #{query}
      ) AS search_results
      ON search_results.wdpa_id = protected_areas.wdpa_id
    """.squish).returns(order_mock)

    Search.search search_query
  end

  test '#search sanitizes potential SQL injections' do
    search_query = "' --"

    query = """
      SELECT wdpa_id, ts_rank(document, query) AS rank
      FROM tsvector_search_documents, to_tsquery(''':* & --:*') query
      WHERE document @@ query
    """.squish

    order_mock = mock()
    order_mock.stubs(:order).returns([])

    ProtectedArea.expects(:joins).with("""
      INNER JOIN (
        #{query}
      ) AS search_results
      ON search_results.wdpa_id = protected_areas.wdpa_id
    """.squish).returns(order_mock)

    Search.search search_query
  end

  test '#search squishes the query and joins the lexemes with & (and) operators' do
    search_query = ' Killbear and   the Manbone'

    query = """
      SELECT wdpa_id, ts_rank(document, query) AS rank
      FROM tsvector_search_documents, to_tsquery('Killbear:* & and:* & the:* & Manbone:*') query
      WHERE document @@ query
    """.squish

    order_mock = mock()
    order_mock.stubs(:order).returns([])

    ProtectedArea.expects(:joins).with("""
      INNER JOIN (
        #{query}
      ) AS search_results
      ON search_results.wdpa_id = protected_areas.wdpa_id
    """.squish).returns(order_mock)

    Search.search search_query
  end

  test '#search populates the results attribute of Search' do
    results = []

    order_mock = mock()
    order_mock.stubs(:order).returns([])

    ProtectedArea.expects(:joins).returns(order_mock)

    Search.any_instance.expects(:results=).with(results).twice

    Search.search 'search'
  end

  test '#search_for_similar calls Search::Similarity to fetch similitarities' do
    search_term = 'manbone'

    Search::Similarity.expects(:search).with(search_term).returns([])

    Search.search_for_similar search_term
  end

  test '#reindex executes the REFRESH command on Postgres' do
    ActiveRecord::Base.connection.expects(:execute).with("""
      REFRESH MATERIALIZED VIEW tsvector_search_documents
    """.squish)

    Search.reindex
  end
end
