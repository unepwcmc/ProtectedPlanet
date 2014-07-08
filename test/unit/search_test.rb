require 'test_helper'

class TestSearch < ActiveSupport::TestCase
  test '#search runs a full text search and returns the matching PA models' do
    search_query = 'manbone'

    query = """
      SELECT wdpa_id, ts_rank(document, query) AS rank
      FROM tsvector_search_documents, to_tsquery('#{search_query}') query
      WHERE document @@ query
    """.squish

    order_mock = mock()
    order_mock.expects(:order).with("rank DESC")

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
      FROM tsvector_search_documents, to_tsquery(''' & --') query
      WHERE document @@ query
    """.squish

    order_mock = mock()
    order_mock.stubs(:order)

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
      FROM tsvector_search_documents, to_tsquery('Killbear & and & the & Manbone') query
      WHERE document @@ query
    """.squish

    order_mock = mock()
    order_mock.stubs(:order)

    ProtectedArea.expects(:joins).with("""
      INNER JOIN (
        #{query}
      ) AS search_results
      ON search_results.wdpa_id = protected_areas.wdpa_id
    """.squish).returns(order_mock)

    Search.search search_query
  end
end
