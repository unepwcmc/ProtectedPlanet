class Search
  def self.search search_term
    search_instance = self.new search_term
    search_instance.search
  end

  def initialize search_term
    @search_term = search_term
  end

  def search
    protected_area_ids = DB.execute(query)
    ids_to_protected_areas protected_area_ids
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

  def ids_to_protected_areas ids
    protected_areas = ids.map do |pa|
      ProtectedArea.find(pa["id"])
    end

    protected_areas.compact
  end
end
