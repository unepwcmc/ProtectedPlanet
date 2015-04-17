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

    merge_tables and move_to_permanent_table
  end

  private

  def query_cartodb query
    @options[:query][:q] = query
    self.class.get('/', @options)
  end

  def merge_tables
    tables_to_merge.each do |table_name|
      response = query_cartodb table_merge_query(table_name)
      return false unless response.code == 200
    end

    true
  end

  def table_merge_query table_name
    """
      INSERT INTO #{merge_table}
        (#{column_names})
        SELECT #{column_names} FROM #{table_name};
      DROP TABLE #{table_name};
    """.squish
  end

  def move_to_permanent_table
    response = query_cartodb rename_query
    return response.code == 200
  end

  def rename_query
    """
      BEGIN;
        DROP TABLE IF EXISTS #{permanent_table_name}_backup;
        ALTER TABLE #{permanent_table_name} RENAME TO #{permanent_table_name}_backup;
        ALTER TABLE #{merge_table} RENAME TO #{permanent_table_name};
      COMMIT;
    """.squish
  end

  def permanent_table_name
    if !!(merge_table =~ Wdpa::DataStandard::Matchers::POLYGON_TABLE)
      "wdpa_poly_#{Rails.env}"
    else
      "wdpa_point_#{Rails.env}"
    end
  end

  def tables_to_merge
    @table_names[1..-1]
  end

  def merge_table
    @table_names.first
  end

  def column_names
    @column_names.join(', ')
  end
end
