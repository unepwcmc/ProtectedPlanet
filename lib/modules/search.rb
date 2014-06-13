class Search
  def self.search search_term
    search_instance = self.new search_term
    search_instance.search
  end

  def initialize search_term
    @search_term = search_term
  end

  def search
    ProtectedArea.find(protected_area_ids_for_search)
  end

  private

  DB = ActiveRecord::Base.connection

  def query
    dirty_query = """
      SELECT id
      FROM tsvector_search_documents
      WHERE document @@ to_tsquery(?)
    """.squish

    ActiveRecord::Base.send(:sanitize_sql_array, [
      dirty_query, @search_term
    ])
  end

  def protected_area_ids_for_search
    results = DB.execute(query)
    results.map { |attributes| attributes["id"] }
  end
end
