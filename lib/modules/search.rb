class Search
  attr_reader :search_term, :results

  def self.search search_term
    search_instance = self.new search_term
    search_instance.search
    search_instance
  end

  def self.search_for_similar search_term
    similarities = Search::Similarity.search search_term
    return self.new(search_term) if similarities.empty?

    self.search similarities.first
  end

  def initialize search_term
    self.search_term = search_term
    self.results = []
  end

  def search
    self.results = ProtectedArea.joins(join_query).order('rank DESC')
  end

  private
  attr_writer :search_term, :results

  def join_query
    """
      INNER JOIN (
        #{search_query}
      ) AS search_results
      ON search_results.wdpa_id = protected_areas.wdpa_id
    """.squish
  end

  def search_query
    dirty_query = """
      SELECT wdpa_id, ts_rank(document, query) AS rank
      FROM tsvector_search_documents, to_tsquery(?) query
      WHERE document @@ query
    """.squish

    ActiveRecord::Base.send(:sanitize_sql_array, [
      dirty_query, search_term
    ])
  end

  def search_term
    lexemes = @search_term.split(' ')
    lexemes = lexemes.map{|lexeme| "#{lexeme}:*"}
    lexemes.join(' & ')
  end
end
