class Search
  DB = ActiveRecord::Base.connection

  def self.search search_term
    search_instance = self.new search_term
    search_instance.search
  end

  def initialize search_term
    @search_term = search_term
  end

  def search
    ProtectedArea.where(wdpa_id: protected_area_wdpa_ids_for_search)
  end

  private

  def protected_area_wdpa_ids_for_search
    results = DB.execute(query)
    results.map { |attributes| attributes["wdpa_id"] }
  end

  def query
    dirty_query = """
      SELECT wdpa_id
      FROM tsvector_search_documents
      WHERE document @@ to_tsquery(?)
    """.squish

    ActiveRecord::Base.send(:sanitize_sql_array, [
      dirty_query, search_term
    ])
  end

  def search_term
    @search_term.squish.gsub(/\s+/, ' & ')
  end
end
