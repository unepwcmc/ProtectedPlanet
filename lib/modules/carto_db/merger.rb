class CartoDb::Merger
  include HTTParty
  default_timeout 1800

  def initialize username, api_key
    self.class.base_uri "https://#{username}.cartodb.com/api/v2/sql"
    @options = { query: { api_key: api_key } }
  end

  def merge table_names, column_names, default_table
    @table_names = table_names
    @column_names = column_names
    @default_table = default_table

    merge_query.each do |query|
      response = query_cartodb(query)
      return false unless response.code == 200
    end

    rename

    return true
  end

  def join_tables
    merge_query.each do |query|
      response = query_cartodb(query)

      return false unless response.code == 200
    end
  end

  def rename
    temp_table = @table_names[0]
    query = rename_transaction(temp_table)
    response = query_cartodb(query)

    return false unless response.code == 200
  end

  private

  def query_cartodb query
    @options[:query][:q] = query
    self.class.get('/', @options)
  end

  def merge_query
    merge_candidates.map do |table_name|
      """INSERT INTO #{@table_names[0]} (#{column_names}) SELECT #{column_names} FROM #{table_name};
       DROP TABLE #{table_name};""".squish
    end
  end

  def rename_transaction temp_table
    """BEGIN;
       DELETE FROM #{@default_table};
       INSERT INTO #{@default_table}
          SELECT * FROM #{temp_table};
       DROP TABLE #{temp_table};
       COMMIT;""".squish
  end

  def merge_candidates
    @table_names.drop(1)
  end

  def column_names
    @column_names.join(', ')
  end
end
