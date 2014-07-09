class Search::Similarity
  attr_accessor :word, :similarity

  def self.search search_term
    results = ActiveRecord::Base.connection.execute(
      search_query(search_term)
    )

    results.map do |result|
      self.new result['word'], result['similarity']
    end
  end

  def initialize word, similarity
    self.word = word
    self.similarity = similarity
  end

  class << self
    private

    def search_query search_term
      dirty_query = """
        SELECT word, similarity(word, ?) AS similarity
        FROM search_lexemes
        WHERE word % ?
        ORDER BY similarity DESC;
      """.squish

      ActiveRecord::Base.send(:sanitize_sql_array, [
        dirty_query, search_term, search_term
      ])
    end
  end
end
