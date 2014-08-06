class CartoDb::NameChanger
  include HTTParty
  default_timeout 1800

  def initialize username, api_key
    self.class.base_uri "https://#{username}.cartodb.com/api/v2/sql"
    @options = { query: { api_key: api_key } }
  end

  def rename default_table, temp_table
    query = transaction(default_table, temp_table)

    @options[:query][:q] = query
    response = self.class.get('/', @options)

    return response.code == 200 ? true : false
  end

  private

  def transaction default_table, temp_table
    """BEGIN;
       DELETE FROM #{default_table};
       INSERT INTO #{default_table}
          SELECT * FROM #{temp_table};
       DROP TABLE #{temp_table};
       COMMIT;""".squish
  end
end