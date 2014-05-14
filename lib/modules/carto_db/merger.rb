class CartoDb::Merger
  include HTTParty

  def initialize username, api_key
    self.class.base_uri "https://#{username}.cartodb.com/api/v2/sql"
    @options = { query: { api_key: api_key } }
  end

  def merge table_names, column_names
    @table_names = table_names
    @column_names = column_names

    @options[:query][:q] = merge_query
    response = self.class.get('/', @options)

    return response.code == 200
  end

  private

  def merge_query
    "INSERT INTO #{@table_names[0]} (#{union_tables_query})"
  end

  def merge_candidates
    @table_names.drop(1)
  end

  def union_tables_query
    table_queries = merge_candidates.map do |table_name|
      "SELECT #{@column_names} FROM #{table_name}"
    end

    table_queries.join(' UNION ALL ')
  end
end
