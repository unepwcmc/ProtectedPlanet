class CartoDb::Merger
  include HTTParty

  def initialize username, api_key
    self.class.base_uri "https://#{username}.cartodb.com/api/v2/sql"
    @options = { query: { api_key: api_key } }
  end

  def merge table_names
    @table_names = table_names
    @columns =  "the_geom, wdpaid, wdpa_pid, name, orig_name, country, sub_loc, desig, desig_eng, desig_type, iucn_cat, int_crit, marine, rep_m_area, gis_m_area, rep_area, gis_area, status, status_yr, gov_type, mang_auth, mang_plan, no_take, no_tk_area, metadataid, shape_leng, shape_area"

    @options[:query][:q] = merge_query
    response = self.class.get('/', @options)

    return response.code == 200
  end

  private

  def merge_query
    "INSERT INTO #{@table_names[0]} (#{union_tables_query})"
  end

  def union_tables_query
    table_queries = @table_names.drop(1).map { |table_name| "SELECT #{@columns} FROM #{table_name}" }
    table_queries.join(' UNION ALL ')
  end
end
