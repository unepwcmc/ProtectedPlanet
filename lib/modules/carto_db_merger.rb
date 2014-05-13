class CartoDbMerger
  def merge table_names
    @table_names = table_names

    cartodb_username = Rails.application.secrets.cartodb_username
    cartodb_api_key  = Rails.application.secrets.cartodb_api_key
    cartodb_url      = "http://#{cartodb_username}.cartodb.com/api/api/v2/sql"

    Typhoeus.get(cartodb_url,
      params: {
        q: merge_query,
        api_key: cartodb_api_key
      }
    )
  end

  private

  def merge_query
    "INSERT INTO #{@table_names[0]} (#{union_tables_query})"
  end

  def union_tables_query
    table_queries = @table_names.drop(1).map { |table_name| "SELECT * FROM #{table_name}" }
    table_queries.join(' UNION ALL ')
  end
end