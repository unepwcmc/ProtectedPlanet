class CartoDb::NameChanger
  include HTTParty
  default_timeout 1800

  def initialize username, api_key
    self.class.base_uri "https://#{username}.cartodb.com/api/v2/sql"
    @options = { query: { api_key: api_key } }
  end

  def delete_current current_table
    query = delete_query(current_table)
    full_transaction = transaction(query)

    @options[:query][:q] = full_transaction
    response = self.class.get('/', @options)

    return response.code == 200 ? true : false
  end

  def insert_new current_table, temp_table
    query = insert_query(current_table, temp_table)
    full_transaction = transaction(query)

    @options[:query][:q] = full_transaction
    response = self.class.get('/', @options)

    return response.code == 200 ? true : false

  end

  private

  def delete_query table
    """DELETE FROM #{table};""".squish
  end

  def transaction query
    """BEGIN;
       #{query}
       COMMIT;""".squish
  end

  def insert_query destination, source
    """INSERT INTO #{destination}
       SELECT * FROM #{source};""".squish
  end



end