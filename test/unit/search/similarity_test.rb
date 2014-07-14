require 'test_helper'

class SearchSimilarityTest < ActiveSupport::TestCase
  test '#search calls the DB with the search_term' do
    search_term = 'manbone'

    query = """
      SELECT word, similarity(word, '#{search_term}') AS similarity
      FROM search_lexemes
      WHERE word % '#{search_term}'
      ORDER BY similarity DESC;
    """.squish
    ActiveRecord::Base.connection.expects(:execute).with(query).returns([])

    Search::Similarity.search search_term
  end
end
