class Search
  DB = ActiveRecord::Base.connection

  def self.search search_term, pagination_options = nil
    search_instance = self.new search_term, pagination_options
    search_instance.search
  end

  def self.count search_term
    search_instance = self.new search_term, nil
    search_instance.count
  end

  def initialize search_term, pagination_options
    @search_term = search_term
    @pagination_options = pagination_options
  end

  def search
    ProtectedArea.where(wdpa_id: protected_area_wdpa_ids_for_search)
  end

  private

  def protected_area_wdpa_ids_for_search
    results = DB.execute(query)
    results.map { |attributes| attributes["wdpa_id"] }
  end

  def query select_attributes = 'wdpa_id'
    dirty_query = """
      SELECT #{Array.wrap(select_attributes).join(', ')}
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
