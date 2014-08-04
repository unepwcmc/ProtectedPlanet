class CartoDb::Merger
  include HTTParty
  default_timeout 1800

  def initialize username, api_key
    self.class.base_uri "https://#{username}.cartodb.com/api/v2/sql"
    @options = { query: { api_key: api_key } }
  end

  def merge table_names, column_names
    @table_names = table_names
    @column_names = column_names

    merge_query.each do |query|
      @options[:query][:q] = query
      response = self.class.get('/', @options)

      return false unless response.code == 200
    end

    return true
  end

  private

  def merge_query
    merge_candidates.map do |table_name|
      """INSERT INTO #{@table_names[0]} (#{column_names}) SELECT #{column_names} FROM #{table_name};
       DROP TABLE #{table_name};""".squish
    end
  end

  def merge_candidates
    @table_names.drop(1)
  end

  def column_names
    @column_names.join(', ')
  end
end
